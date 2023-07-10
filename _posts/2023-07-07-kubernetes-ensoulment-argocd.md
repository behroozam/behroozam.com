---
layout: post
comments: true
title: "دمیدن روح به کوبرنتیز با ArgoCD"
date: 2023-07-07
categories: development
image: assets/article_images/argocd/argocd.png
toc: true
---

از وقتی بلاگ نویسی رو شروع کردم یادم میاد که میخواستم به بقیه چیزایی که بلدم رو یاد بدم ولی نکته اینه که میون این همه محتوای آموزشی که روی اینترنت وجود داره خیلی راحت امکانش وجود داره که محتوای من گم بشه پس با خودم گفتم چیزی که من مینویسم باید تجربه خودم باشه نه صرفا چیزی که به راحتی با سرچ کردن میتونه به دست بیاد. 
یعنی نقطه اتصالی باشه بین دانسته های مختلفی که دارم و تجربیاتم و سعی کردم اینو تو پست های وبلاگم هم انعکاس بدم.

درمورد کوبرنتیز چون تبدیل به یگانه orchestrator و PaaS برنده بازار شد طبیعی که این تعداد این مطالب بیشتر باشه. 

اما بزارید در مورد این صحبت کنم که 

### چرا کالبد کوبرنتیز

قبل از کوبرنتیز هم ارکستریتر های دیگه ای وجود داشتن من شخصا طرفدار [رنچر](https://www.rancher.com/) بودم ولی خیلی ها هم از [سوارم](https://docs.docker.com/engine/swarm/) استفاده میکردن. 
زیرساخت سنتی تر مبتنی بر baremetal یا vm  بود که عملا ایزوله کردن اپلیکیشن ها رو از همدیگه رو غیرممکن یا خیلی سخت میکرد.[این](https://www.backblaze.com/blog/vm-vs-containers/) یه مقایسه خوبه درمورد مجازی سازی درمقابل کانتینر. 
 
 ![](assets/article_images/argocd/containers-vs-virtual-machines.jpg "vm vs container")


سربار vm نسبت به کانتینر خیلی بیشتر بود و bootstrap کردنشم خیلی طول میکشید یا نیاز به زیرساخت خودش رو داشت مثل زیرساحت IaaS. 
اونچیزی که به نظرم باعث برتری و درنهایت استاندارد شدن کوبرنتیز کرد دیزاین برتری بودش که با تجربه گوگل به دست اومده بوده 
دیزاینی که از همون اولش انترپرایز بود 
کوبرنتیز با مفهوم namespace برای جدا کردن tenant ها 
و با مفهوم پاد برای ایزوله کردن یک یا تعدادی از کانتینرها و استفاده از [CRI](https://kubernetes.io/docs/concepts/architecture/cri/) و [CSI](https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/) و [CNI](https://www.tigera.io/learn/guides/kubernetes-networking/kubernetes-cni/) 
تونست ماژولار باشه و برای تعداد خیلی زیادی از شرکت ها جذاب باشه.

 ![](assets/article_images/argocd/k8s-multi-tenancy.png "k8s multi tenancy")

جامعه کاربری که دور کوبرنتیز هم شکل گرفت باعث شد که این lifescycle توسعه نرم افزار متحول بشه چیزی که امروز بهش میگیم [cloud native applications](https://landscape.cncf.io/) محصول این تحوله. 

<object data="https://landscape.cncf.io/images/landscape.pdf" width="100%" height="100%" type='application/pdf'></object>


این بلوغ و شکوفایی کوبرنتیز هنوز به انتهای خودش نرسیده 
دور این اکوسیستم ابزارهای مسیریابی و لاگ و سنجه و استقرار و .... 
شکل گرفته که امروز میخوام درمورد یکی از محبوب ترین ابزارهای استقرار[^1] یعنی ArgoCD صحبت کنم. یکم درمورد معماریش و اینکه چطور کار میکنه و بعد درمورد اینکه چطوری میشه یه نسخه HA و تر و تمیز ازش بالا اورد و البته سناریو های مختلفی که ممکنه ما باهاشون رو به رو بشیم یا بهشون نیازمند باشیم. 

### ArgoCD چیست و چگونه روح رو به کالبد کوبرنتیز میدمه ؟ 

### تاریخچه استقرار در دوران کرتاسه و کوبرنتیز 

این استعاره روح و بدن خیلی مورد علاقه دوستان فلسفه و تئولوژیه ولی شاید برای توصیف مرز زیرساخت و استقرار به کار بیاد 
اصولا مفهوم دواپس هم برای کمرنگ کردن این مرز به وجود اومد.

 در دوران [کرتاسه](https://fa.wikipedia.org/wiki/%DA%A9%D8%B1%D8%AA%D8%A7%D8%B3%D9%87) سیس ادمین ها زیرساخت و امنیت و دسترسی رو ایجاد و مدیریت میکردن و شاید اگه استقراری هم درکار بود تو فواصل زمانی خیلی دیر به دیر نرم افزار رو به روزرسانی میکردن حالا به مدل سنتی و با ftp یا sftp یا مدل یکمی آپدیت تر و به وسیله ابزار های source control مثل git یا Configuration management مثل ansible یا chef. 

 اما با تغییر پارادایم های توسعه نرم افزار به سمت چارچوب هایی مثل Agile همه چیز به سمت سریع تر شدن پیش رفت پس لازم بود که سریع Deploy کرد و سریع Fail شد و rollback کرد این با سیستم سنتی سیس ادمین خسته و دولوپر تنها تو اتاق 3x4 شدنی نبود. 
همون جوری که یه دود و دم خوب زغال خوب میخواد لازمه این تغییر پارادایم هم ابزار خوب بود.

> اگه ما کوبرنتیز رو دود دم درنظر بگیریم یعنی کیف و حال زیرساخت و توسعه نرم افزار ArgoCD میشه زغال خوب.  

حالا که درمورد تاریخچه صحبت کردم بزارید درمورد این صحبت کنم که قبل از اینکه ابزارهایی مثل [Flux](https://fluxcd.io/) و [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) و [Spinnaker](https://spinnaker.io/) وجود داشتن از چه چیزی برای دیپلوی روی کوبرنتیز استفاده میشد. 

همون طور که میدونید مدل کوبرنتیز client و server هستش و resource ها به صورت declarative درخواست میشن. برای فهمیدن تفاوت Imperative و Declarative خوندن [این مقاله](https://programiz.pro/resources/imperative-vs-declarative-programming/#:~:text=Imperative%20programming%20specifies%20and%20directs,about%20how%20the%20program%20works.) رو توصیه میکنم.

 ![](assets/article_images/argocd/declarative-vs-imperative.jpg "declarative vs imperative ")

 اگه این ریسورس معتبر باشه یعنی kube-api و validation webhook ها تشخیص بدن که میشه این ریسورس رو ساخت درنهایت status این ریسورس اپدیت میشه و ساخته میشه در غیر این صورت بسته به اینکه ارور ما معنایی هستش یا لغوی از ساخته شدن ریسورس جلوگیری میشه. 

از اونجایی که هیچ چیزی بهتر از مثال نمیتونه راحت تر معنا رو برسونه من میام و یه کلاستر تستی رو میسازم و سعی میکنم روش یه پاد رو استقرار کنم 

برای ساختن کلاستر های تستی و توسعه کوبرنتیز هیچ چیزی رو ساده تر از [k3s](https://k3s.io/) نیافتم برای حتی راحت تر کردن ساخت کلاستر های k3s شرکت رنچر که قبلا هم گفته بودم از ابزار های محبوب منه اومده و یه ابزار کوچولو و خیلی خوبی رو ساخته به اسم [k3d](https://k3d.io/). 

تصور میکنم که شما از یه سیستم linux استفاده میکنید و docker و kubectl رو هم روی سیستمون نصب دارید 
من خودم الان روی سیستم ویندوزی خودم با HyperV و ubuntu server 22.04 هستم. 
 
#### نصب و راه اندازی اولین کلاستر تستی کوبرنتیزمون به وسیله k3d
![](assets/article_images/argocd/k3d.png "k3d")

ابتدا اخرین k3d رو نصب میکنیم 
```
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
بعد یه کلاستر تستی رو میسازیم 

```
 k3d cluster create local-k8s --servers 1 --agents 3
```
اگه همه چیز به خوبی پیش رفته باشه وقتی میزنیم 
```
kubectl cluster-info
```
باید کلاسترتون رو ببینید که به خوبی و خوشی داره کار میکنه 

اما بریم سراغ اولین دیپلوی روی کلاستر تستی خودمون  
این manifest اولین پادی هست که میخوایم روی default namespace اعمال کنیم 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80

```
از اونجایی که kubectl ریسورس های ریموت رو هم قبول میکنه من ازلینک رسمی خود مخزن رسمی کوبرنتیز استفاده میکنم ولی شما میتونید همین فایل yaml  بالا رو ذخیره کنید و اجرا کنید 

```
#if you savaed the pod  manifest in file 
# kubectl apply -f simple-pod.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/pods/simple-pod.yaml
```

اگه همه چیز به خوبی و خوشی انجام شده باشه شما باید ببینید که پاد شما ساخته شده و درحال اجرا هستش 

```
➜  ~ k get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          2m14s
```
 این میشه ساده ترین مدل استقراری که manifest های declarative کوبرنتیز رو اعمال کرد. 
اما مثل هر چیز ساده ای این مدل دیپلوی کردنم ضعف هایی داره که باعث میشه به درد سناریوهای سازمان ها شرکت ها و حتی تیم های کوچیک نخوره . 
بیاین چند تا سناریو یکم پیچیده تر رو باهم برسی کنیم؟ 
* چی میشه اگه به جای یه محیط توسعه چند تا محیط توسعه داشته باشیم مثلا development و staiging و production 
* چی میشه اگه بخوایم نسخه های مختلفی از نرم افزارمون رو روی تو محیط های مختلف داشته باشیم
* چی میشه اگه بخوایم از pipeline های CI/CD برای توسعه نرم افزارمون استفاده کنیم 

دراوردن یه روش تر و تمیز مهندسی شده که جوابگوی سناریو های پیچیده تر ما باشه نیاز به ابزارهای پیچیده تری داره که در ادامه درموردشون صحبت میکنم. 

#### استقرار به روش kustomize یا Helm

برای جواب دادن به نیازهای بالا جامعه کاربری کوبرنتیز تعداد خیلی زیادی ابزار ایجاد کرد که به نظر من در انتها این دوتا بین اهالی دنیای CNCF مقبول تر افتادن.

* [Helm](https://helm.sh/) 
* [kustomize](https://kustomize.io/)

سناریو های بالا رو تصور کنید که ما سه namespace داریم 

*  Prod => Production
* Stg => Staiging
* Dev => Development 

میایم و این نیم اسپیس ها رو تو کلاستر تستسی که ساختیم ایجاد میکنیم
 
```
for ns in prod dev stg
kubectl create ns $ns
```

احتمالا شما با resource های دیگه کوبرنتیز مثل [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) و [Statefulset](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) هم آشنایی دارید که برای دیپلوی نرم افزار روی کلاستر کوبرنتیز منطقی تر هستند ولی چون هدف این پست بلاگ آموزشی هستش من با همون ساده ترین شکل ریسورس که پاد[^2] باشه ادامه میدم و برای اینکه مثال ها در دسترس باشه و بعدا ازشون برای َArgoCD استفاده کنیم یه [مخزن](https://github.com/behroozam/kubernetes-deployment-example) روی گیتهاب میسازم. 

##### kustomize 
![](assets/article_images/argocd/kustomize.png "kustomize")

برای اینکه از kustomize برای دیپلوی کردن روی سه namespace ای که ساختیم استفاده کنم همچین ساختار فایلی رو ایجاد میکنم که تو [مخزن](https://github.com/behroozam/kubernetes-deployment-example) گیتهابم موجود هستش و میتونید clone کنید 
```
.
|-- base
|   |-- kustomization.yaml
|   `-- simple-pod.yaml
|-- kustomization.yaml
`-- overlays
    |-- dev
    |   `-- kustomization.yaml
    |-- prod
    |   `-- kustomization.yaml
    `-- stg
        `-- kustomization.yaml

```
و برای ساختن خروجی که مد نظرمون هستش کافیه که این کامند رو اجرا کنیم 

```
kustomize build

```
کاستومایز خودش به تنهایی کار دیپلوی کردن روی کلاستر کوبرنتیز ما انجام نمیده صرفا یه template engine که خروجی مانیفست های مد نظر ما رو در انتها ایجاد میکنه 
پس برای اعمال این مانیفست ها روی کلاستر کوبرنتیز خودمون لازمه که خروجی kustomize  رو به kubectl پایپ کنیم. 

```
kustomize build | kubectl apply -f  -
```

##### Helm 
![](assets/article_images/argocd/helm.svg "helm")

هلم یا حلم :)) یکی از محبوب ترین ابزارهای کانفیگ/دیپلوی کوبرنتیز هستش برتری هایی نسبت به kustomize داره که میشه گفتش به نسبت ابزار بهتر و کامل تریه به چند دلیل 

* هلم رو میشه به صورت چارت[^3] استفاده کرد و ورژن زد یعنی میشه ورژن های مختلفی از یه چارت داشت 
* هلم رو میشه rollback  کرد ولی برای kustomize به همین سادگی فشردن یه دکمه نیست 
* هلم برنامه نویس پسند تره یعنی میشه فانکشن های کاستوم یا helper نوشت که کار نوشتن تمپلیت ها رو راحت تر میکنه 
* مستقل از kubectl و لزومی به داشتنش نداره 

اما بریم به سراغ دیپلوی کردن پاد nginx به وسیله helm 

```
#clone kubernetes examples repo
git clone https://github.com/behroozam/kubernetes-deployment-example.git
#change directory to examples
cd kubernetes-deployment-example/examples
#Deploy helm chart to each environment 
for env in dev stg prod 
helm install nginx-pod ./helm --namespace $env

```
و برای لیست کردن رلیز های خودمون میتونیم اینشکلی لیست رلیز های خودمون رو ببینیم
 
```
helm list --all-namespaces
```


#### با این وجود چه نیازی به ArgoCD وجود داره ؟ 

پس شاید بپرسید که با وجود داشتن helm و kustomize  چه لزومی به یه ابزار سومی مثل ArgoCD وجود داره 

همون طوری که هلم و کاستومایز برای پاسخ دادن به نیاز کاربرایی ایجاد شدن که نیاز به آزادی عمل بیشتری برای دیپلویمنت های خودشون داشتند.

 ArgoCD هم برای شرکت ها و سازمان ها و تیم ها واصولا جاهایی که نیاز به همکاری برای دیپلوی کردن اپلیکیشن ها دارن ایجاد شد. 

از حدود 5 6 سال قبل یه مفهومی خیلی پرطرفدار شده و تا به امروز هم پرطفدار باقی مونده به اسم GitOps. 

##### Gitops چیه؟ 

من دنبال تعریف کتابی و ویکیپدیایی از گیتاپس نیستم به نظرم همون طوری که خیلی دقیق نمیشه دواپس رو تعرف کرد گیتاپسم دست آدمی رو باز میزاره برای تعریف خودش. من فکر میکنم وقتی فهمیدیم که Git چقدر کار توسعه رو راحت میکنه و میتونیم تغییرات رو ببینیم و PR بدیم و ... کلا flow کار خیلی روان و راحت شد تو توسعه نرم افزار مخصوصا به صورت تیمی. 
این رو ذهنیت همگی تاثیرگذاشت به صورتی که توافق کردیم که هرانچیزی که روی ریپازیتوری های ما هست باید تو پروداکشن هم باشد. 

#### ArgoCD چطور از GitOps استفاده میکنه ؟ 

به نظرم جواب این سوال که آرگو چطور از گیت‌آپس استفاده میکنه سوال چیستی ArgoCD رو هم پاسخ میده 
میشه گفتش اینجا نقطه تلاقی دوتا از بهترین استراکچر هایی که تا حالا درموردشون صحبت کردیم یعنی مانیفست های کوبرنتیز که declarative بودن و git که قابلیت همکاری تیمی رو به ما میداد. 

مزیت سومی هم که آرگو رو نسبت به رقبا برتری میده پشتیبانی کردنش از هر سه روشی که بالا برای دیپلوی زدن مثال زدم یعنی kubectl و helm  و kustomize  هستش. 
با این تفاوت که دست ما برای اینکه روی کلاستر های مختلف و namespace های مختلف دیپلوی کنیم بازه 

بزارید دوباره وارد عالم مثال ها بشیم و این شکلی راحت تر متوجه بشیم 
برای این مسئله با k3d به جای ساختن یه دونه کلاستر من چهارتا کلاستر ایجاد میکنم که یکیشون وظیفه control plane ارگو رو بر عهده داره و سه تای دیگه محیط توسعه هستن 

#### دیپلوی ArgoCD به وسیله Helm روی کلاستر k3d 

اول چهارتا کلاستر رو ایجاد میکنیم 
```
k3d cluster create argocd-control-plane  --servers 1 --agents 1
for cluster in dev stg prod
k3d cluster create $cluster  --servers 1 --agents 1
```
بعد به وسیله helm ارگو رو روی کلاستر argocd-control-plane نصب میکنیم 
[این](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd) آدرس چارت رسمی argocd هستش 

توجه کنید که برای کاستومایز کردن نصب ArgoCD برای نیاز خودتون لازمه که مقدار value ها رو عوض کنید ولی من چون هدف اینجا آموزشی و کلاستر ها هم تستی هستن از مقادیر دیفالت استفاده میکنم 

من برای سویچ کردن بین cluster های مختلفی که توی kubeconfig خودم دارم از ctx و برای namespace ها از پلاین ns استفاده میکنم که میتونید از طریق [این](https://dev.to/aws-builders/kubectl-cli-plugins-ctx-and-ns-1696) آموزش نصبشون کنید 

```
k ctx k3d-argocd-control-plane
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --namespace argocd --create-namespace
```
اگه همه چیز به خوبی پیش رفته باشه کافیه که حالا پورت argocd رو port-forward کنید 
```
kubectl port-forward service/argocd-server -n argocd 8080:443 --address='0.0.0.0'
```

حالا اگه ادرس vm یا ماشینتون رو روی borwser بازکنید باید به همچین اخطاری مواجه بشید که درمورد ssl هستش این رو بایپس کنید و وارد صفجه لاگین بشین 
برای کردنشیال میتونید پسورد ابتدایی که ArgoCD میسازه رو به این صورت دریافت کنید 

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

حالا داستان جذاب کار کردن با خود manifest های ArgoCD شروع میشه ولی بزارید ابتدا بریم سراغ اضافه کردن کلاستر های فعلی که داریم به ArgoCD تا بتونیم pod خودمون رو درنهایت روی همه کلاستر های خودمون اجرا کنیم 

##### اضافه کردن کلاستر های موجود به ArgoCD 

همون طور که بالا دیدین مایه کلاستر برای نصب ArgoCD ایجاد کردیم و سه کلاستر دیگه که نماینده محیط های توسعه مختلف ما باشن 
تو دنیای دواپس و با تعاریف دواپسی به همچین حالتی میگن multi cluster and multi tenant یعنی ما چند کلاستر داریم که میتونن چندین namespace هرکدوم توی خودشون جا بدن 

برای اضافه کردن cluster ها راحت ترین کار استفاده از [cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/) خود argocd هستش

> توجه کنید که k3d به صورت دیفالت از آدرس 0.0.0.0 برای ادرس context شما استفاده میکنه برای اینکه بتونید از api کلاسترتون تو ArgoCD هم استفاده کنید باید از آپشن --api-port استفاده کنید برای مثال 
k3d cluster create dev --api-port 192.168.168.108:6448 


```
argocd login 0.0.0.0:8080
argocd cluster add k3d-dev --name dev
argocd cluster add k3d-stg --name stg
argocd cluster add k3d-prod --name prod
```
اگه همه چیز با موفقت پیش رفته باشه ArgoCD سه ریسورس روی کلاستر مقصد ساخته و کلاستر های شما روی ArgoCD server شما باید به این شکل باشه 
آرگو برای اینکه بتونه روی کلاستر های ریموت دسترسی داشته باشه و manifest ها رو بسازه و مدیریت یا مانیتور کنه نیازداره که دسترسی cluster wide داشته باشه برای همین میاد و سه ریسورس رو روی کلاستر ریموت میسازه 

```
k get clusterroles.rbac.authorization.k8s.io argocd-manager-role
k get clusterrolebindings.rbac.authorization.k8s.io argocd-manager- 
k get sa -n kube-system argocd-manager
```

#### ساختن ApplicationSet روی ArgoCD 

تا اینجای کار ما کلاستر هامون رو به آرگو اضافه کردیم و اگه همه چیز خوب پیشرفته باشه میرسیم به اصل ماجرا یعنی دیپلوی کردن اپلیکیشن های خودمون روی env های مختلف 
ساده ترین مدل دیپلوی روی Argocd به وسیله Application که [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)  هستش اتفاق میفته برای مثال میخوام که پادی که با kubectl ساختم رو روی کلاستر stg اجرا کنم 

اول نیازه که یه manifest رو برای Application که nginx-pod هستش ایجاد کنم 

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-pod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/behroozam/kubernetes-deployment-example.git
    targetRevision: HEAD
    path: examples/kubectl/
  destination:
    server: https://192.168.168.108:6445

```
ادرس سرور چیزی که تو kubeconfig خودتون به عنوان آدرس کلاستر دارین ( درواقع kube-apiserver )

بعد از اینکه این مانیفست رو به کلاستر argocd-control-plane اپلای کنید میبینید که اپلیکیشن ساخته میشه ولی sync نیست. 

[پالیستی دیفالت](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/) ArgoCD اینجوری که برای sync کردن تغییراتی که روی ریپازیتوری گیت خودتون دارید باید به صورت دستی دکمه sync رو بزنید ولی خب میشه این رو هم به حالت اتوماتیک تغییر داد 
اگه همه چیز خوب پیشرفته باشه پاد ما ساخته شده و درحال اجراست به این صورت 
```
 k get pods  -n default --context k3d-prod
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          6m55s
```

همون طور که گفتم اپلیکیشن ساده ترین مدل دیپلویمنت ما هستش و نیازهای ما رو برای مدل های پیچیده تر دیپلوی حل نمیکنه 
تصور کنید که لازم باشه که روی بیش از یک کلاستر و یک نیم‌اسپیس دیپلوی داشته باشیم 
در این صورت باید برای هرکدام از کلاستر ها و نیم اسپیس ها یه اپلیکیشن جداگانه بسازیم که از حوصله اکثر ماها دواپس های خسته خارجه. 
برای این مسئله ArgoCD از ApplicationSet  استفاده میکنه که مجموعه ای از یه سری generator ها برای ساختن کانفیگ اپلیکیشن های ما هستن 

یرای مثال تصور کنید که میخوایم هلم چارت nginx  رو به این صورت دیپلوی کنیم 
* prod cluster => green namespace 
* stg cluster => red namespace 

میایم و از جنریتور cluster برای این مسئله استفاده میکنیم ولی قبلش برای اینکه کلاستر ها رو از هم بتونیم تفکیک کنیم بهشون label اضافه میکنیم برای مثال `cluseterenv` 

حالا این مانیفست ApplicationSet رو اعمال میکنیم.

> توجه کنید که حتما مانیفست رو روی نیم اسپیس argocd و روی کلاستر control-plane اعمال کنید در غیر این صورت argocd وقعی به ریسورسی که تو namespace های دیگه ایجاد کرده باشید نمیزاره 


```
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: nginx-pod
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          clusterenv: stg
      values:
        namespace: red
  - clusters:
      selector:
        matchLabels:
          clusterenv: prod
      values:
        namespace: green
  template:
    metadata:
      name: 'nginx-pod-{{nameNormalized}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/behroozam/kubernetes-deployment-example.git
        path: examples/helm
        helm:
          releaseName: nginx-pod-{{values.namespace}}
      destination:
        server: '{{server}}'
        namespace: '{{values.namespace}}'
      syncPolicy:
        syncOptions:
          - CreateNamespace=true
```
حالا اگه همه چیز به خوبی پیش رفته باشه باید این دوتا اپلیکیشن رو ببینید که باید sync بشن 

و بعد از سینک شدن همه چیز باید سبز باشه 

##### چیزایی که باید بعدا اضافه کنم مثل ACL و PROJECT و SSO 

[^1]: Deployment
[^2]: [Pod](https://kubernetes.io/docs/concepts/workloads/pods/)
[^3]: [Chart](https://helm.sh/docs/topics/charts/)

