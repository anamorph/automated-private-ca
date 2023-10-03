#!/bin/bash
################################################################################
#	Version History
#	----------------------------------------------------------------------------
#	v1.0		nicolas@	 Initial Version
#	v1.1		nicolas@	 Minor fixes
#
################################################################################
if [ "$#" -ne 3 ]
	then
		echo -e "Not enough arguments\n"
		echo -e "usage: private-certificate_authority.sh %profile% %region% %env%\n"
		echo -e "Example: private-certificate_authority.sh default eu-west-1 prod\n"
	else
		echo -n "
		Are you sure you want to proceed with

					profile: $1
					region: $2
					env: $3

		yes/no ?"
		read answer
		#
		if [ "$answer" != "${answer#[Yy]}" ] ;
			then
				# forcing cleaning variables
				unset PCA_ALREADY_EXISTS
				unset PCA_ID
				#
				# creating dynamic timestamp, always handy
				timestamp() {
					date +"%Y%m%d-%H%M%S"
				}
				#
				# checking for existing Private CAs
				export PCA_ALREADY_EXISTS=$(aws acm-pca list-certificate-authorities \
					--query "CertificateAuthorities[?Status != 'DELETED'][Arn,Status]" \
					--output text \
					--profile $1 \
					--region $2)
				#
				if [[ ! -z $PCA_ALREADY_EXISTS ]]
					then
						echo -e "\n\nYou already have existing/awaiting validation PCAs:\n--------------------------------------------------------------------------------------------------------------\n$PCA_ALREADY_EXISTS\n--------------------------------------------------------------------------------------------------------------\nThis doesn't look good.\n\nAbort! Abort!."
						exit 1
					else

						################################################################################
						# 0. creating directory structure
						################################################################################
						export MYCERTROOT=$PWD/keys/CertAuthority
						echo -e "\n### Creating directory/file structure"
						#
						# Root CA directory
						#
						mkdir $MYCERTROOT/certs
						mkdir $MYCERTROOT/crl
						mkdir $MYCERTROOT/csr
						mkdir $MYCERTROOT/newcerts
						mkdir $MYCERTROOT/private
						chmod 700 $MYCERTROOT/private
						touch $MYCERTROOT/index.txt
						echo 1000 > $MYCERTROOT/serial
						#
						# Intermediate CA directory
						#
						mkdir $MYCERTROOT/intermediate
						mkdir $MYCERTROOT/intermediate/certs
						mkdir $MYCERTROOT/intermediate/crl
						mkdir $MYCERTROOT/intermediate/csr
						mkdir $MYCERTROOT/intermediate/newcerts
						mkdir $MYCERTROOT/intermediate/private
						chmod 700 $MYCERTROOT/intermediate/private
						touch $MYCERTROOT/intermediate/index.txt
						echo 1000 > $MYCERTROOT/intermediate/serial
						echo 1000 > $MYCERTROOT/intermediate/crlnumber
						#
						# copy OpenSSL configuration file to Intermediate CA Directory
						cp openssl_intermediate.cnf $MYCERTROOT/intermediate/
						#
						#
						################################################################################
						# 1. creating our private CA
						################################################################################
						echo -e "\n### Press enter to adjust the following file to your customer's details"
						read rsp
						# copy to private-certificate_authority.json-timestamp
						cp private-certificate_authority.json private-certificate_authority.json-`timestamp`
						vi private-certificate_authority.json
						#
						echo -e "\n### Creating Private CA"
						aws acm-pca create-certificate-authority \
							--certificate-authority-configuration file://private-certificate_authority.json \
							--certificate-authority-type SUBORDINATE \
							--tags Key=Environment,Value=$3 \
							--profile $1 \
							--region $2
						# # waiting for PCA to be available
						sleep 1
						#
						#
						# exporting our Private CA Arn to a variable
						export PCA_ID=$(aws acm-pca list-certificate-authorities --query "CertificateAuthorities[?Status == 'PENDING_CERTIFICATE'][Arn]" --output text --profile $1 --region $2)
						#
						# getting our Private CA's CSR
						echo -e "\n### Downloading Private CA CSR"
						aws acm-pca get-certificate-authority-csr \
							--certificate-authority-arn $PCA_ID \
							--output text \
							--profile $1 \
							--region $2 > $MYCERTROOT/CSR.pem
						#
						################################################################################
						# 2. Generate CA key
						################################################################################
						echo -e "\n### Generating ROOT CA Key"
						openssl genrsa \
							-aes256 \
							-out $MYCERTROOT/private/ca.key.pem 4096
						chmod 400 $MYCERTROOT/private/ca.key.pem
						#
						# Generate CA certificate
						echo -e "\n### Generating ROOT CA Certificate"
						openssl req -config openssl.cnf \
							-key $MYCERTROOT/private/ca.key.pem \
							-new -x509 -days 7300 -sha256 -extensions v3_ca \
							-out $MYCERTROOT/certs/ca.cert.pem
						chmod 444 $MYCERTROOT/certs/ca.cert.pem
						#
						# check certificate data
						openssl x509 -noout -text -in $MYCERTROOT/certs/ca.cert.pem
						#
						################################################################################
						# 3. Generate Intermediate key
						################################################################################
						export INTERMEDIATE_CA_DIR=$(sed -n '7p' openssl.cnf | awk -F"=" '{print $2}')
						echo -e "\n### Generating INTERMEDIATE CA Key"
						openssl genrsa -aes256 \
							-out $MYCERTROOT/intermediate/private/intermediate.key.pem 4096
						chmod 400 $MYCERTROOT/intermediate/private/intermediate.key.pem
						#
						# Generate Certificate Signature Request - CSR
						echo -e "\n### Generating INTERMEDIATE CA CSR"
						openssl req -config $MYCERTROOT/intermediate/openssl_intermediate.cnf -new -sha256 \
							-key $MYCERTROOT/intermediate/private/intermediate.key.pem \
							-out $MYCERTROOT/intermediate/csr/intermediate.csr.pem
						# Sign Certificate with CSR
						echo -e "\n### Generating INTERMEDIATE CA Cert, with CSR"
						openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
							-days 3650 -notext -md sha256 \
							-in $MYCERTROOT/intermediate/csr/intermediate.csr.pem \
							-out $MYCERTROOT/intermediate/certs/intermediate.cert.pem
						#
						################################################################################
						# 4. Generate CA Chain (Intermediate + Root)
						################################################################################
						echo -e "\n### Generating CA Chain"
						cat $MYCERTROOT/intermediate/certs/intermediate.cert.pem \
							$MYCERTROOT/certs/ca.cert.pem > $MYCERTROOT/intermediate/certs/ca-chain.cert.pem
						chmod 444 $MYCERTROOT/intermediate/certs/ca-chain.cert.pem
						#
						# Sign Subordinate Certificate with CSR from Private CA
						echo -e "\n### Signing Subordinate Certificate with CSR from Private CA"
						openssl ca \
							-config openssl.cnf \
							-extensions v3_intermediate_ca \
							-days 3650 \
							-notext \
							-md sha256 \
							-in $MYCERTROOT/CSR.pem \
							-out $MYCERTROOT/certs/subordinate_cert.pem
						#
						################################################################################
						# 5. Importing our stuff into our Private CA
						################################################################################
						echo -e "\n### Importing Certs and CA Chain into Private CA"
						aws acm-pca import-certificate-authority-certificate \
							--certificate-authority-arn $PCA_ID \
							--certificate file://$MYCERTROOT/certs/subordinate_cert.pem \
							--certificate-chain file://$MYCERTROOT/certs/ca.cert.pem \
							--profile $1 \
							--region $2
						#
						#
						# checking our Private CA's Status
						aws acm-pca list-certificate-authorities \
							--query "CertificateAuthorities[?Status != 'DELETED'][Arn,Status]" \
							--output table \
							--profile $1 \
							--region $2
						#
						# compressing the results to archive
						echo -e "\n### Pushing versions to file"
						echo -e "OPENSSL VERSION\n---" > $MYCERTROOT/lib_versions_used.txt
						openssl version >> $MYCERTROOT/lib_versions_used.txt
						echo -e "\n\nOS VERSION\n---" >> $MYCERTROOT/lib_versions_used.txt
						uname -a >> $MYCERTROOT/lib_versions_used.txt
						echo -e "\n### Backing up data to ../`timestamp`-certificate_authority.tar.gz"
						tar -zcvf ../`timestamp`-certificate_authority.tar.gz .
					fi
			else
				echo "Aborting."
		fi
fi
