---
layout: post
comments: true
title: "ساختن کلاستر کوبرنتیز با رنچر روی هاروستر و اندکی گیک بازی"
date: 2026-04-27
categories: development
image: assets/article_images/harvester-homelab-setup/harvester-homelab-setup.png
toc: true
---

## مقدمه: اکوسیستم Rancher

توی دنیای self-hosted راه‌های زیادی برای ساختن کلاستر Kubernetes وجود داره، ولی یکی از ابزارهایی که خیلی محبوب و پر استفاده‌ست اکوسیستم Rancher‌ه. قبل از اینکه بریم سراغ مراحل عملی، یه توضیح اجمالی بدم درباره پروژه‌های اصلی که زیرمجموعه Rancher هستن و به چه کار می‌آن:

{% mermaid %}
graph TD
    %% تعریف ساختار هرمی با استفاده از زیرمجموعه‌ها

    subgraph Top [PaaS]
        RKE2["<b>RKE2</b><br/>(کلاستر کوبرنتیز امن و سبک)"]
    end

    subgraph Middle [Management & Control]
        RM["<b>Rancher Manager</b><br/>(کنترل و مشاهده کل کلاسترها)"]
        H["<b>Harvester</b><br/>(زیرساخت مجازی سازی و HCI)"]
    end

    subgraph Base [Foundation]
        LH["<b>Longhorn Storage</b><br/>(ذخیره‌سازی توزیع شده)"]
        VM["<b>Virtual Compute</b>"]
    end

    %% ایجاد سلسله مراتب بصری
    RKE2 --- RM
    RM --- H
    H --- LH
    H --- VM

    %% استایل‌دهی برای نمایش بهتر
    style RKE2 fill:#ffeb3b,stroke:#fbc02d,stroke-width:3px
    style RM fill:#2196f3,stroke:#1976d2,color:#fff
    style H fill:#ff9800,stroke:#f57c00,color:#fff
    style Top fill:none,stroke:none
    style Middle fill:none,stroke:none
    style Base fill:#f5f5f5,stroke:#9e9e9e,stroke-dasharray: 5 5
{% endmermaid %}

- **Rancher Manager (Rancher UI):** وظیفه ساختن و مدیریت کلاسترهای Kubernetes رو داره. از اینجاست که همه چیز رو می‌بینیم و کنترل می‌کنیم.
- **Harvester:** یه پلتفرم مجازی‌سازی هایپرکانورجد هست که virtual machine و distributed storage رو با هم بهمون می‌ده. زیر بنای storage‌ش هم **Longhorn** ه.
- **RKE2:** یه توزیع سبک Kubernetes بر مبنای k3s‌ه که تمرکزش روی امنیت، سرعت و سازگاری با اکوسیستم Rancher و Longhorn هست.

پس از نظر لایه‌بندی می‌شه گفت:

- **لایه IaaS** ← Harvester
- **لایه Platform (PaaS)** ← RKE2 + Rancher



## چرا Harvester؟ (و یه هشدار مهم)

توی [پست قبلی](/proxmox-pxe-boot) توضیح دادم که چطور با Netboot و dnsmasq روی لپ‌تاپم
Proxmox نصب کردم. اما در میانه‌ی راه تصمیم گرفتم مسیرم رو عوض کنم و به سمت Harvester برم.

### فروپاشی اکوسیستم VMware

احتمالاً خبر دارید که بعد از تصاحب VMware توسط Broadcom، هزینه‌ها و پیچیدگی‌های لایسنس
به شکل چشمگیری افزایش پیدا کرد. از نسخه‌ی ۸ به بعد، مدل لایسنس‌دهی به سمتی رفت که
عملاً بازیگرهای کوچک و متوسط رو از معادله حذف می‌کنه. علاوه بر این، حتی برای
provisioning اولیه هم به منابع سخت‌افزاری قابل‌توجهی نیاز داره.

این تغییرات برای تیم‌ها و شرکت‌هایی که زیرساختشون رو روی VMware بنا کرده بودن یک
زنگ خطر جدی بود و جستجو برای جایگزین رو اجتناب‌ناپذیر کرد.

### Harvester به‌عنوان جایگزین واقعی

Harvester یک پلتفرم HCI (Hyper-Converged Infrastructure) متن‌بازه است که توسط SUSE
پشتیبانی می‌شه. این پشتیبانی از یک شرکت enterprise معتبر، یعنی چرخه‌ی پشتیبانی بلندمدت،
patch های امنیتی منظم، و SLA قابل استناد — چیزهایی که برای زیرساخت production حیاتی‌اند.


## چرا Harvester و نه Proxmox؟

هر دو پلتفرم مجازی‌سازی و Software-Defined Storage رو ارائه می‌دن:

| ویژگی | Harvester | Proxmox |
|---|---|---|
| مجازی‌سازی | KubeVirt | KVM/QEMU |
| Storage | Longhorn | Ceph |
| لایه مدیریتی | Kubernetes-native | اختصاصی |
| یکپارچگی با Rancher | بله (built-in) | خیر |
| مدل لایسنس | متن‌باز (Apache 2.0) | BSL / Enterprise |

### مزیت‌های کلیدی Harvester

**۱. Kubernetes-native بودن**
Harvester روی بستر Kubernetes ساخته شده، نه اینکه صرفاً یک لایه‌ی مدیریتی روی
hypervisor باشه. این یعنی VM‌ها، containerها و زیرساخت شبکه همه از طریق Kubernetes
API مدیریت می‌شن و با ابزارهای GitOps مثل ArgoCD و Flux سازگاری کامل دارن.

**۲. یکپارچگی با Rancher**
Harvester از روز اول با Rancher طراحی شده که کار می‌کنه. این یعنی می‌تونید مستقیماً
از داخل Harvester، کلاسترهای Kubernetes مدیریت‌شده (RKE2/K3s) بسازید — بدون نیاز
به ابزار جداگانه یا تنظیمات دستی اضافه.

**۳. Single pane of glass**
با Proxmox معمولاً مجبورید برای مدیریت VM‌ها یک ابزار، برای کانتینرها ابزار دیگه‌ای،
و برای Kubernetes یک ابزار سوم داشته باشید. Harvester این سه رو در یک رابط یکپارچه
می‌کنه.

**۴. Longhorn به‌جای Ceph**
Ceph قدرتمنده، اما راه‌اندازی و نگهداریش پیچیده‌ست و به cluster سه‌ node یا بیشتر
برای reliable بودن نیاز داره. Longhorn سبک‌تر، ساده‌تر، و برای محیط‌های کوچک‌تر
مناسب‌تره — در عین حال replication و snapshot رو هم پشتیبانی می‌کنه.

**۵. مسیر مهاجرت از VMware**
ابزار `vm-import-controller` در Harvester امکان مهاجرت مستقیم از VMware vSphere رو
فراهم می‌کنه — این برای تیم‌هایی که دارن از VMware فرار می‌کنن یک مزیت عملی جدی‌ه.


> ⚠️ **نکته مهم قبل از شروع:**
> Harvester حتی بدون ساختن کلاستر Kubernetes هم در حالت عادی منابع زیادی مصرف می‌کنه. از این نظر برای homelab با سخت‌افزار متوسط یا ضعیف — جایی که مصرف پایین برق و مدیریت بهینه منابع اهمیت زیادی داره — گزینه ایده‌آلی نیست. این رو در نظر بگیرید قبل از اینکه شروع کنید.



## مرحله اول: بوت کردن Harvester از طریق Netboot

برای بوت Harvester از طریق netboot دو کار باید بکنیم:

1. تغییر کانفیگ iPXE مخصوص Harvester
![](assets/article_images/harvester-homelab-setup/harvester-ipxe.png "Harvester IPXE")
2. دانلود asset‌های پیش‌فرض موردنیاز
![](assets/article_images/harvester-homelab-setup/netboot-local-assets.png "Harvester netboot local assets")
من از آخرین نسخه داکر netboot استفاده می‌کنم پس آخرین آپدیت‌ها رو هم دارم. کافیه این فایل‌ها رو از remote assets دانلود کنم:

```
/assets/asset-mirror/releases/download/v1.4.0-c82c6d22/harvester-amd64.sha512
/assets/asset-mirror/releases/download/v1.4.0-c82c6d22/harvester-initrd-amd64
/assets/asset-mirror/releases/download/v1.4.0-c82c6d22/harvester-rootfs-amd64.squashfs
/assets/asset-mirror/releases/download/v1.4.0-c82c6d22/harvester-vmlinuz-amd64
/assets/asset-mirror/releases/download/v1.7.1-fcf0fd7f/harvester.yaml
```

برای پیدا کردن آدرس ISO، وارد دایرکتوری asset‌ها میشیم و فایل `version.yaml` رو می‌خونیم:

```bash
cd assets/asset-mirror/releases/download/v1.7.1-fcf0fd7f
cat version.yaml
```

```yaml
apiVersion: harvesterhci.io/v1beta1
kind: Version
metadata:
  name: v1.7.1
  namespace: harvester-system
spec:
  isoChecksum: '381e6c6d09f4d5d1cb1b3813c1ad5dd8064618e5e5400b36fc26f05cea1425dd87659f93b7f34cd303d13289da7b34c5aa63ec935a8922c0e17ff733100ab361'
  isoURL: https://releases.rancher.com/harvester/v1.7.1/harvester-v1.7.1-amd64.iso
  releaseDate: '20260209'
```

حالا ISO رو دانلود می‌کنیم:

```bash
wget https://releases.rancher.com/harvester/v1.7.1/harvester-v1.7.1-amd64.iso .
```



## مرحله دوم: کانفیگ iPXE برای Harvester

الان وقتشه که کانفیگ iPXE Harvester رو عوض کنیم. فایل زیر رو ویرایش کنید:

```bash
#!ipxe

# Harvester - Hardcoded Config Version
# Target Config: http://192.168.1.156:4000/harvester/harvester.yml

set harvester_config_url http://192.168.1.156:4000/harvester/harvester.yml
set os Harvester
set os_arch amd64

:harvester
menu ${os} - ${os_arch} (Automated)
item --gap Harvester:
item harvester_url ${space} Begin Hardcoded Install (v1.7.1)
item --gap Parameters:
item harvester_config_url ${space} Edit Config URL (Currently: ${harvester_config_url})
choose --default harvester_url menu || goto harvester_exit
echo ${cls}
goto ${menu} ||
goto harvester_exit

:harvester_config_url
echo -n Set config.yaml URL:  && read harvester_config_url
clear menu
goto harvester

:harvester_url
set harvester_url ${live_endpoint}/asset-mirror/releases/download/v1.7.1-fcf0fd7f/
goto harvester_boot

:harvester_boot
set install_params harvester.install.automatic=true harvester.install.config_url=${harvester_config_url}
set boot_params ip=dhcp net.ifnames=1 console=ttyS0 console=tty1 rd.cos.disable root=live:${harvester_url}/harvester-rootfs-${os_arch}.squashfs rd.noverifyssl

imgfree
kernel ${harvester_url}/harvester-vmlinuz-${os_arch} ${install_params} ${boot_params} initrd=initrd.magic ${cmdline}
initrd ${harvester_url}/harvester-initrd-${os_arch}
echo
echo Booting Harvester with config from ${harvester_config_url}
boot

:harvester_exit
clear menu
exit 0
```

> **نکته:** پارامتری که اینجا تغییر دادم `harvester_config_url` هست. از اونجایی که netboot رو روی آدرس `192.168.1.156` اجرا می‌کنم، موقع نصب هم فایل ISO و هم `harvester.yml` رو از همین آدرس می‌گیره.



## مرحله سوم: ساختار دایرکتوری و فایل‌های موردنیاز

توی دایرکتوری `assets` یه دایرکتوری جدید به اسم `harvester` می‌سازیم:

```
├── ./harvester
│   ├── ./harvester/harvester.iso
│   ├── ./harvester/harvester.yml
│   └── ./harvester/ssh_keys
```

فایل ISO رو به این دایرکتوری منتقل می‌کنیم و اسمش رو به `harvester.iso` تغییر می‌دیم.



## مرحله چهارم: کانفیگ نصب Harvester

حالا فایل `harvester.yml` رو می‌سازیم. این فایل تمام تنظیمات خودکار نصب رو داره، از جمله اطلاعات شبکه، دیسک، VIP و رمز عبور:

```yaml
schemeversion: 1
serverurl: ""
token: xxxx # این توکن رو عوض کنید
sans: []
os:
  afterinstallchrootcommands: []
  sshauthorizedkeys:
    - # کلید عمومی SSH خودتون رو اینجا بزارید
  hostname: harvester
  modules:
    - kvm
    - vhost_net
  sysctls: {}
  ntpservers:
    - 0.suse.pool.ntp.org
    - 1.suse.pool.ntp.org
  dnsnameservers: []
  password: # خروجی دستور mkpasswd -m sha-512 رو اینجا بزارید
  environment: {}
  labels: {}
  sshd:
    sftp: false
  persistentstatepaths: []
  externalstorage:
    enabled: false
    multipathconfig: null
  additionalkernelarguments: ""
install:
  automatic: true
  skipchecks: true
  mode: create
  managementinterface:
    interfaces:
      - name: enp0s31f6    # اینترفیس شبکه خودتون رو بنویسید
        hwaddr: e8:80:xxxxx # مک آدرس کارت شبکه‌تون رو بنویسید
    method: dhcp  # اگه IP استاتیک دارید، این رو به static تغییر بدید
    ip: ""
    subnetmask: ""
    gateway: ""
    defaultroute: true
    bondoptions:
      miimon: "100"
      mode: active-backup
    mtu: 0
    vlanid: 0
  vip: 192.168.1.157          # IP مدیریتی Harvester در شبکه شما
  viphwaddr: ""
  vipmode: static
  clusterdns: ""
  clusterpodcidr: ""
  clusterservicecidr: ""
  forceefi: false
  device: /dev/nvme0n1
  configurl: http://192.168.1.156:4000/harvester/harvester.yml  # آدرس netboot سرور شما
  isourl: http://192.168.1.156:4000/harvester/harvester.iso     # آدرس netboot سرور شما
  silent: false
  poweroff: false
  noformat: false
  debug: false
  tty: ttyS0
  forcegpt: true
  role: default
  withnetimages: false
  wipealldisks: false
  wipediskslist: []
  forcembr: false
  datadisk: ""
  webhooks: []
  addons: {}
  harvester:
    storageclass:
      replicacount: 1  # چون single node هستیم؛ در کلاستر چندنوده این رو روی 3 بزارید
    longhorn:
      defaultsettings:
        guaranteedenginemanagercpu: null
        guaranteedreplicamanagercpu: null
        guaranteedinstancemanagercpu: null
        storagereservedpercentagefordefaultdisk: 0
    enablegocoverdir: false
  rawdiskimagepath: ""
  persistentpartitionsize: 286Gi
runtimeversion: v1.34.3+rke2r3
rancherversion: v2.13.1
harvesterchartversion: 1.7.1
monitoringchartversion: 107.1.0+up69.8.2-rancher.15
systemsettings:
  ntp-servers: '{"ntpServers":["0.suse.pool.ntp.org","1.suse.pool.ntp.org"]}'
loggingchartversion: 107.0.1+up4.10.0-rancher.10
kubeovnoperatorchartversion: 1.14.10
```



## مرحله پنجم: بوت و تأیید نصب

مراحل بوت رو پشت سر می‌زاریم. اگه همه چیز درست پیش رفته باشه، کلاستر تک‌نود Harvester ما می‌آد بالا.

یوزر پیش‌فرض OS هاروستر `rancher` هست و از طریق اون به کلاستر وصل میشیم:

```bash
ssh rancher@192.168.1.105
```

برای تأیید وضعیت، `screendump 1` رو اجرا کنید. باید یه چنین خروجی ببینید:

```
┌─ Harvester Cluster ────────────────────────────────────────────────────────┐
│ * Management URL:                                                           │
│   https://192.168.1.157                                                     │
│                                                                             │
│ * Status: Ready                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ Node ─────────────────────────────────────────────────────────────────────┐
│ * Hostname: harvester                                                       │
│ * IP Address: 192.168.1.105                                                 │
│                                                                             │
│ * Status: Ready                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```



## مرحله ششم: تنظیمات شبکه در Harvester

![](assets/article_images/harvester-homelab-setup/harvester-homenetwork.png "Harvester Home Network")

چون من توی شبکه خانگیم VLAN ندارم، گزینه **Untagged Network** رو انتخاب می‌کنم. این باعث میشه که VM‌هایی که می‌سازیم بتونن از طریق bridge از DHCP آدرس IP بگیرن.



## مرحله هفتم: آپلود ایمیج برای VM

برای ساختن VM نیاز داریم به یه ایمیج `qcow2` با پشتیبانی از cloud-init. من از Debian Bookworm استفاده می‌کنم ولی شما می‌تونید هر ایمیج cloud-init دیگه‌ای که باهاش راحت‌تر هستید رو انتخاب کنید:

```bash
wget https://laotzu.ftp.acc.umu.se/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```

بعد از دانلود، این ایمیج رو از تب **Images** در Harvester UI به صورت file آپلود کنید.

![](assets/article_images/harvester-homelab-setup/harvester-debian-image.png "Harvester DEbian Image Upload")


## مرحله هشتم: ساختن Rancher Server VM

الان یه VM برای Rancher Server می‌سازیم. برای disk size مقدار **50 گیگابایت** کافیه. تنظیمات cloud-init رو در قسمت **Advanced Options** وارد کنید:



**User Data:**

```yaml
#cloud-config
package_update: true
packages:
  - qemu-guest-agent
users:
  - name: behrouz
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - your-ssh-public-key-here

runcmd:
  - - systemctl
    - enable
    - --now
    - qemu-guest-agent.service
ssh_authorized_keys:
  - ssh-rsa YOUR_KEY_HERE
```

> **توصیه:** اگه با ساختار و عملکرد cloud-init آشنایی ندارید، قبل از ادامه وقت بزارید و درموردش مطالعه کنید. این ابزار خیلی قدرتمنده و درک درستش بعداً خیلی کمکتون می‌کنه.

**Network Config:**

```yaml
network:
  version: 2
  ethernets:
    all-en:
      match:
        name: "en*"
      dhcp4: true
```

> **توصیه:** این تنظیمات رو به صورت **template** ذخیره کنید تا بعداً هم توی ساختن کلاستر از همشون استفاده کنیم.



## مرحله نهم: نصب Rancher روی VM

به `rancher-server` وصل میشیم، Docker نصب می‌کنیم و Rancher رو اجرا می‌کنیم:

```bash
ssh behrouz@192.168.1.112

# نصب Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
sudo usermod -aG docker behrouz
exit

# اتصال مجدد و اجرای Rancher
ssh behrouz@192.168.1.112
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged rancher/rancher:v2.14.0
```

> **توجه:** این روش یعنی Rancher رو به صورت **single node** اجرا می‌کنیم که برای homelab و محیط آموزشی مناسبه. ولی برای محیط production همیشه سعی کنید حداقل **3 نود** در ماشین‌های جداگانه داشته باشید.

چند دقیقه صبر کنید تا نصب تموم بشه، بعد bootstrap password رو بگیرید:

```bash
# ID کانتینر Rancher رو پیدا کنید
docker ps

# لاگ رو بخونید و bootstrap password رو بیرون بکشید
docker logs 5b6933b359a0 2>&1 | grep "Bootstrap Password:"
```

با این پسورد وارد Rancher UI بشید و **Harvester UI Plugin** رو از قسمت Extensions نصب کنید. اگه نصب پلاگین به مشکل خورد، یه بار دیگه امتحان کنید.



## مرحله دهم: Import کردن Harvester به Rancher

بعد از نصب پلاگین، گزینه Import Harvester رو می‌زنید. Rancher یه فایل YAML برای شما generate می‌کنه. این فایل رو بردارید و به Harvester اضافه کنید:

از تنظیمات Harvester وارد **Advanced → Settings** بشید و مقدار `cluster-registration-url` رو به چیزی شبیه این تغییر بدید:

```
https://192.168.1.112/v3/import/zslj74fbjrklhxqnr447frjsj5bxxxxxxxxxxxxx.yaml
```

چند دقیقه بعد کلاستر Harvester توی Rancher نشون داده میشه.



## مرحله آخر: ساختن کلاستر Kubernetes با Harvester در Rancher

حالا به نقطه تلاقی Rancher و Harvester رسیدیم — جایی که کلاسترمون رو می‌سازیم و اپلیکیشن‌هامون رو اجرا می‌کنیم.

فرایند کلی اینه:

1. **ساختن کلاستر جدید** از طریق Rancher UI با انتخاب Harvester به عنوان Infrastructure Provider
2. **اضافه کردن Node Pool** با تنظیماتی که بسته به محیط شما می‌تونه فرق داشته باشه

![](assets/article_images/harvester-homelab-setup/cluster-image-and-network.png "Rancher Harvester Downstream Cluster Network and Image")

![](assets/article_images/harvester-homelab-setup/cluster-user-network-cloudinit.png "Rancher Harvester Downstream Cluster Netowork and User Data Cloudinit")


چون من یه کلاستر single-node Harvester دارم، باید این مقادیر رو به تنظیمات YAML کلاستر اضافه کنم تا توی مرحله bootstrap گیر نکنه:

```yaml
global:
  cattle:
    clusterName: cool-cluster
  tolerations:
    - effect: NoSchedule
      key: node.cloudprovider.kubernetes.io/uninitialized
      operator: Exists
    - effect: NoSchedule
      key: node-role.kubernetes.io/control-plane
      operator: Exists
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
```

> **توضیح:** این toleration‌ها لازم هستن چون در یه محیط single-node، بعضی node‌ها ممکنه در ابتدا uninitialized باشن یا نقش control-plane داشته باشن. بدون این تنظیمات، workload‌های cloud provider نمی‌تونن روی اون نود schedule بشن و کلاستر توی مرحله bootstrap می‌مونه.



## جمع‌بندی

تا اینجا یه زیرساخت کامل خونگی داریم:

- **Harvester** به عنوان لایه IaaS که مجازی‌سازی و storage رو با هم مدیریت می‌کنه
- **Rancher** به عنوان کنترل پنل مرکزی
- یه **کلاستر Kubernetes** آماده برای deploy کردن اپلیکیشن

قدم بعدی؟ نصب ابزارهایی مثل ArgoCD برای GitOps، یا راه‌اندازی Longhorn برای persistent storage — ولی این‌ها داستان پست‌های بعدیه.
