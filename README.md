# automated-private-ca
## TL;DR;
automated-private-ca is a sample Amazon Certificate Manager automation to create your very own Private Certificate Authority in Amazon Certificate Manager (ACM). **This is content is provided as is: a sample to demonstrate the art of possible with ACM PCA - Amazon Certificate Manager Private Certificate Authority.**

## What ?
AWS Certificate Manager Private Certificate Authority is a managed private CA service with which you can easily and securely manage your certificate authority infrastructure and your private certificates. ACM PCA provides a highly available private CA service without the investment and maintenance costs of operating your own certificate authority. ACM PCA extends ACM certificate management to private certificates, enabling you to manage public and private certificates in one console.

Private certificates identify resources within an organization. Examples include clients, servers, applications, services, devices, and users. In establishing a secure encrypted communications channel, each resource endpoint uses a certificate and cryptographic techniques to prove its identity to another endpoint. Internal API endpoints, web servers, VPN users, IoT devices, and many other applications use private certificates to establish encrypted communication channels that are necessary for their secure operation.

Both public and private certificates help customers identify resources on networks and secure communication between these resources. Public certificates identify resources on the public internet whereas private certificates do so for private networks. One key difference is that applications and browsers trust public certificates by default whereas an administrator must explicitly configure applications to trust private certificates. Public CAs, the entities that issue public certificates, must follow strict rules, provide operational visibility, and meet security standards imposed by the browser and operating system vendors. Private CAs are managed by private organizations, and private CA administrators can make their own rules for issuing private certificates. These include practices for issuing certificates and what information a certificate can include.

To get started using ACM PCA, you must have an intermediate or root CA available for your organization. This might be an on–premises CA, or one that is in the cloud, or one that is commercially available. Create your private CA and then use your organization's CA to create and sign the private CA certificate. After the certificate is signed, import it back into ACM PCA.

## Why ?
Previously, if a customer wanted to use private certificates, they needed specialized infrastructure and security expertise that could be expensive to maintain and operate. ACM Private CA builds on ACM’s existing certificate capabilities to help you easily and securely manage the lifecycle of your private certificates with pay as you go pricing. This enables developers to provision certificates in just a few simple API calls while administrators have a central CA management console and fine grained access control through granular IAM policies. ACM Private CA keys are stored securely in AWS managed hardware security modules (HSMs) that adhere to FIPS 140-2 Level 3 security standards. ACM Private CA automatically maintains certificate revocation lists (CRLs) in Amazon Simple Storage Service (S3) and lets administrators generate audit reports of certificate creation with the API or console.
### 1. Encrypt everything
### 2. Security on your servers
### 3. Cost
You are charged for private certificates whose private key you can access. This includes certificates that you export from ACM and certificates that you create from the ACM PCA API or ACM PCA CLI. You are not charged for a private certificate after it has been deleted. However, if you restore a private CA, you are charged for the time between deletion and restoration. Private certificates whose private key you cannot access are free. These include certificates that are used with Integrated Services such as Elastic Load Balancing, CloudFront, and API Gateway.

As of the last revision of this document, pricing is as follows:

**Private Certificate Authority Operation**

**$400** per month for each ACM private CA **until you delete the CA**.
ACM Private CA operation is pro-rated for partial months based on when you create and delete the CA. You are not charged for a private CA after you delete it. However, if you restore a deleted CA, you are charged for the time between deleting it and restoring it.

**Private Certificates**

|Number of private certificates created in the month/per Region | Price (per certificate)  |
|---------------------------------------------------------------|--------------------------|
| 1 - 1,000                                                     |                    $0.75 |
| 1,001 - 10,000                                                |                    $0.35 |
| 10,001 and above                                              |                   $0.001 |

## How ?
### Installation

Use the package manager [brew](https://brew.sh) to install the dependencies required for automated-private-ca:

```bash
brew install openssl@1.0.2t
brew install awscli
```

### Usage

```bash
./private-certificate_authority.sh

Not enough arguments

usage: private-certificate_authority.sh %profile% %region% %env%

Example: private-certificate_authority.sh nicolas eu-west-1 prod
```

### Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

### Reading material
- https://aws.amazon.com/blogs/aws/aws-certificate-manager-launches-private-certificate-authority/
- https://jamielinux.com/docs/openssl-certificate-authority/introduction.html