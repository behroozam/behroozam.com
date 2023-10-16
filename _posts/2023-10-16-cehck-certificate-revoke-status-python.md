---
layout: post
comments: true
title: "چک کردن revoke گواهینامه SSL به وسیله پایتون"
date: 2023-10-16
categories: development
image: assets/article_images/certificate-revoke/crl-vs-ocsp.png
toc: true
---

گاهی وقت ها لازم میشه که قبل از اینکه یه گواهی نامه SSL به پایان برسه ما اون رو revoke کنیم

#### اما پروسه revoke کردن تو گواهینامه SSL چیه؟

![](assets/article_images/certificate-revoke/pubkey.png "Public key certificate")

گواهی نامه SSL درواقع یه public key که توسط CA امضا شده روشی که برای امضا کردن این Public key استفاده میشه اینه که ما یه درخواست امضا کلید عمومی که شامل اطلاعاتی مثل کمپانی و منطقه زمانی و اطلاعاتی میشه که برای گواهی لازمه رو به یه CA بدیم تا اون رو برای ما امضا کنه و درنهایت یه کلید عمومی امضا شده به ما تحویل بده. [اینجا](https://www.digicert.com/easy-csr/openssl.htm) برای مثال میتونید به راحتی یه درخواست CSR رو برای openssl بسازید و کپی کنید و تو خط فرمان خودتون اجرا کنید.

حالا گاهی وقتا پیش میاد که مثلا کلید خصوصی که باهاش درخواست CSR رو دادیم افشا میشه یا اینکه دیگه تمایلی نداریم که از گواهی فعلی استفاده کنیم و میخوایم که این گواهینامه رو به ملکوت اعلی بفرستیم.

دوتا روش برای اینکار وجود داره که ارائه دهنده های گواهینامه یا CA انجام میدن:

- CRL یا Certificate revocation list
- OCSP یا Online Certificate Status Protocol

این دو روش افزونه یا extention برای گواهینامه های استاندارد x509 هستند

#### روش CRL

![](assets/article_images/certificate-revoke/CRL.png "CRL")

تو روش CRL ارائه دهنده گواهینامه یه لیست از گواهی هایی که به پایان رسیده یا revoke شدن رو برای مرورگر یا سیستم ما ارسال میکنه و اینشکلی باعث میشه که سیستم ما متوجه بشه که اعتبار گواهینامه به پایان رسیده که تو تصویر بالا میتونید فرایندش رو ببینید

#### روش OCSP

![](assets/article_images/certificate-revoke/OCSP-1.png "OCSP")

روش OCSP روش مدرن تریه که کلاینت درخواست اعتبارسنجی رو مستقیما برای CA میفرسته تا تایید کنه

روش OCSP به دو حالت انجام میشه یا خود کلاینت درخواست رو به CA ارسال میکنه یا webserver از قبل درخواست رو ارسال میکنه و همراه با گواهی SSL تحویل کلاینت میده
روش دوم به خاطر اینکه بار رو از روی کلاینت برمیداره روش بهتری برای سخت افزارهایی هستش که توان پردازشی پایین تری رو دارند
مثلا توی nignx [به این صورت](https://support.globalsign.com/ssl/ssl-certificates-installation/nginx-enable-ocsp-stapling) میشه این قابلیت رو فعال کرد.

![](assets/article_images/certificate-revoke/OCSP-Stapling-1.png "OCSP-Stapling")

#### چطوری به وسیله python اعتبار گواهی نامه SSL رو تایید کنیم

برای این کار دوتا wrapper نوشته شده که میتونید از اونا برای validate کردن certificate استفاده کنید

- [crl-checker](https://pypi.org/project/crl-checker/) برای CRL
- [OCSP-Checker](https://pypi.org/project/ocsp-checker/) برای OCSP

من برای راحتی کار یه اسکریپت ساده نوشتم که هردوتا رو استفاده میکنه به این صورت که اول پیش نیاز ها رو نصب میکنیم

```
pip install ocsp-checker crl-checker
```

و بعدش این اسکریپت رو تو یه فایل مثلا `main.py` ذخیره میکنیم

```
import ssl
import argparse
from crl_checker import check_revoked, Revoked, Error
from ocspchecker import ocspchecker

parser = argparse.ArgumentParser()
parser.add_argument("hostname")
parser.add_argument("port")

args = parser.parse_args()


def get_server_certificate(hostname, port):
    cert = ssl.get_server_certificate((hostname, port))
    return cert


def check_server_pem_revoked():
    cert_pem = get_server_certificate(hostname=args.hostname, port=args.port)
    try:
        check_revoked(cert_pem)
    except Revoked as e:
        print(f"Certificate revoked: {e}")
    except Error as e:
        print(f"Revocation check failed. Error: {e}")
        raise


def OCSP_revoked(hostname, port):
    ocsp_request = ocspchecker.get_ocsp_status(host=hostname, port=port)
    return ocsp_request


check_server_pem_revoked()

OCSP_revoked(hostname=args.hostname, port=args.port)


```

و حالا کافیه که ارگیومنت های خودمون رو به اسکریپت تو کامند لاین بدیم به این صورت
برای مثال برای چک کردن گواهی سایت خودم که معتبره

```
python3 main.py behroozam.com 443
```

و برای یه گواهی نامعتبر از این مثالی که [Digicert](https://www.digicert.com/kb/digicert-root-certificates.htm) استفاده میکنم

```
python3 main.py digicert-tls-ecc-p384-root-g5-revoked.chain-demos.digicert.com 443
```
