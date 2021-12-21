# spring admission controller

Spring boot를 이용해 만든 간단한 Kubernetes admission controller 입니다.

Admission controller의 Validating webhook을 이용하여 Pod의 생성을 제한합니다.

<br/>

## Prerequisite
- JDK 17
- Kubernetes v1.16+
- kubectl
- kubens (optional)

<br/>

## Build

### 1. 인증서 생성/서명 및 적용
```
sh gen_certs.sh
```

Admission controller는 https(ssl/tls) 적용이 필수적입니다. 이를 위해 `gen_certs.sh`를 이용합니다.
- 생성 과정에서 비밀번호 입력이 필요합니다. 해당 비밀번호는 `server.ssl.key-store-password` property에 입력해주어야 합니다.

<br/>

`gen_certs.sh` 에서는 다음과 같은 작업을 수행합니다.
- OpenSSL을 이용해 개인키 및 인증서 생성
- Tomcat https 적용을 위한 PKCS#12 인증서 생성
- 인증서 정보를 사용해 `ValidatingWebhookConfiguration` manifest 생성

<br/>

### 2. 컨테이너 이미지 생성

```
./gradlew bootBuildImage --imageName {registry id/image name}:{version}

docker push {registry id/image name}:{version}
```

여기서 입력한 `imageName`은 `kubernetes/server.yml`의 `containers.image`에 입력해주어야합니다.

<br/>

## Run

```
kubens # default namespace 사용

kubectl apply -f kubernetes/server.yml

kubectl apply -f kubernetes/validating-webhook.yml
```

Validating webhook이 적용되었습니다.

<br/>

Pod를 생성하려하면 validating webhook을 통해 해당 프로젝트의 ValidateController로 요청이 가게 되고, 거절 되어 아래와 같은 오류가 출력됩니다.

```
$ kubectl run mynginx --image nginx --restart Never
Error from server (Pod create not allowed): admission webhook "validating-webhook.bb.com" denied the request: Pod create not allowed
```