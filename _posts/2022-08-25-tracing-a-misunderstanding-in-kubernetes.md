---
layout: post
comments: true
title: "ردیابی یه سو تفاهم کوبرنتیزی"
date: 2022-08-25
categories: development
image: assets/article_images/kubernetes/yaml-engineers.jpeg
---

داستان از این قراره که این روزا من دارم روی یه [پروژه باحال](https://github.com/smartlyio/yggdrasil) برای تقسیم بار بین خوشه[^1] های مختلف کوبرنتیز[^2] کار میکنم.

 اگه از سرویس ابری گوگل استفاده میکنید این پروژه چیزی شبیه به [multi cluster ingress controller](https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-ingress) هستش اما تفاوت بزرگش اینه که متن بازه و محدود به هیچ سرویس دهنده خاصی نمیشه وهمه جا میشه ازش استفاده کرد.

به صورت کلی دو نوع مختلف از [global service loadbalancer](https://www.nginx.com/resources/glossary/global-server-load-balancing) وجود داره
dns وhttp و هرکدوم هم مزایا و معایب خودشون رو دارن برای مثال

پروژه [k8GB](https://www.k8gb.io/) که یه پروژه متن بازه از EDNS برای مدیریت کردن سرویس ها بین خوشه های مختلف استفاده میکنه و مزیتش اینه که با تعریف کردن CRD و اتصال EDNS به dns provider میشه به راحتی سرویس ها رو تحت subdomain های مختلف بین کلاستر های مختلف تقسیم بار کرد

ولی dns مشکلات خاص خودش رو هم داره مثل ttl dns که ممکنه توسط مشتری یا واسط تغییر کنه و باعث outage یا مشکلات ناخواسته اینچنینی بشه

 و اینکه dns هیچ درکی از http path نداره و نمیشه از یه dns به صورت هوشمندانه برای تقسیم بار استفاده کرد
برای مثال نمیشه
```
behroozam.com/foo > cluster1
behroozam.com/bar > cluster2
```
فرستاد که باعث شد من پروژه [yggdrasil](https://github.com/smartlyio/yggdrasil) رو که http loadbalancer هستش رو بردارم و بهبود بدم چون علاوه بر اینکه http loadbalancer مفهوم FQDN رو متوجه میشه میتونه محتوای http packet رو باز کنه و بر اساس routing تصمیم بگیره که پکت رو کجا بفرسته.

```
if path is /foo use backend behroozam-cluster1
if path is /bar use backend behroozam-cluster2
```


‍‍‍

این پروژه تمام [ingress resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) هایی که تو خوشه های مختلف کوبرنتیز هست رو میگیره با همدیگه تجمیع میکنه و بر اساس اینکه چه `host` و یا `path` دارن اون هارو برای لودبالانسر envoy دسته بندی و پیکره بندی میکنه که به صورت اتوماتیک بر اساس وجود داشتن یا نداشتن ingress resources تو کلاستر های ما تقسیم بار رو انجام بده.

برای اینکه این کار انجام بشه ما باید یه مرحله اضافی رو علاوه بر گرفتن ingress resources ها از خوشه ها انجام بدیم چون متاسفانه کوبرنتیز هیچ [شاخصه منحصر به فردی](https://github.com/kubernetes/kubernetes/issues/44954) برای خوشه های ما نداره که مشخص کنه هر ingress resource ای به کدوم خوشه تعلق داره.

این مرحله اضافی گرفتن اطلاعات هرکدوم از [kubernetes node](https://kubernetes.io/docs/concepts/architecture/nodes/)  های ما هستش که ingress controller روی اون ها در حال اجرا هستش بر فرض اینکه ما برای دسترسی به [ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) خودمون از NodePort استفاده کردیم.

[NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) درواقع یکی از ServiceTypes  کوبرنتیز هستش که معمولا روی baremetal از اون استفاده میکنیم تا سرویس خودمون رو به وسیله DNAT توسط iptables به خارج از محیط ایزوله kubernetes نمایش بدیم.

### شرح مشکل اما

node خوشه ای که قرار بود NodePort رو به من بده علاوه بر NodePort به `443`  و `80` هم پاسخ میداد و سرویس من به این صورت بود
‍‍‍‍
```
ingress-nginx NodePort 10.10.1.1 <none> 80:30332/TCP,443:30333/TCP 2y194d
```
درواقع این node تنها باید به http request روی  پورت `30333` و `30332‍` پاسخ میداد ولی در کمال تعجب به `443` و `80` هم پاسخ میداد

برای فهم چرایی ماجرا به node ای که وظیفه میزبانی کردن ingress controller رو داشت ssh کردم

ابتدا تلاش کردم متوجه بشم چه پروسه ای روی پورت 80 گوش میده پس این کامند رو اجرا کردم

```
lsof -i tcp:80
```

PID متعلق به systemd-resolved میشد پس میشد حدس زد که این پروسه ربطی به اپلیکیشن های سیتمی نمیشد
خروجی کامند

```
nginx 13902 systemd-resolve 11u IPv4 1835063227 0t0 TCP *:http (LISTEN)
```

برای اینکه مطعا بشم هیچ لودبالانسری روی سیستم نیست که این command رو اجرا کرده باشه تایپ کردم `whereis nginx`
البته که این کامند `whereis` تنها درصورتی جواب برمیگردونه که executable تو مسیر path هایی که تو shell تعریف شده وجود داشته باشه ولی با تقریب بالایی حالا میدونستم که این process مربوط به یه کانتینر روی سیستم میشه
اما برای پیدا کردن اینکه اینکه این PID متعلق به چه کانتینری هستش باید چیکار میکردم ؟
با کمی سرچ کردن به این گفت و گو تو [stackoverflow](https://stackoverflow.com/questions/24406743/coreos-get-docker-container-name-by-pid) رسیدم پس از این کامند استفاده کردم تا PID رو به کانتینر MAP کنم

```
PID=$(lsof -i tcp:80 | awk 'NR==2{print $2}'); sudo docker ps --no-trunc | grep $(cat /proc/$PID/cgroup | grep -oE '[0-9a-f]{64}' | head -1) | sed 's/^.* //'
```
نتیجه متعلق میشد به `k8s_nginx-ingress-controller_nginx-ingress-controller` پس میتونستم مطعما باشم چیزی که باش سروکار دارم مربوط به کوبرنتیز میشه نه چیزی خارج از اون پس برای مرحله بعد باید ingress controller deployment رو چک میکردم
و اینجا بود که متوجه شدم deployment من از Host Ports استفاده میکنه یعنی مستقیما روی port های node گوش میده به این صورت

```bash
kubectl get ds nginx-ingress-controller -o yaml

       ports:
        - containerPort: 80
          hostPort: 80
          name: http
          protocol: TCP
        - containerPort: 443
          hostPort: 443
          name: https
          protocol: TCP
```

برای حل مشکل کافی بود فقط این خطوط رو از deployment خودم پاک میکردم

[^1]: کلاستر
[^2]: kubernetes
