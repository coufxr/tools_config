# django-多app多backend

这是一个奇怪的需求,可能存在错误  
不包含基础的view与url

## 1. Backend:
### 创建多个backend
```python
class PhoneModelBackend(BaseBackend):
    """手机验证码后端"""

    app_user_model: AbstractBaseUser = None

    def __init__(self, app_user_model: AbstractBaseUser, *args, **kwargs):
        self.app_user_model = app_user_model

    def authenticate(self, request, phone="", code="", **kwargs):
        if kwargs["login_type"] != LoginType.PHONE_CAPTCHA:
            return
        
        if self.app_user_model is None:
            raise ValueError("用户模型不能为`None`")
        ...
```

```python
class WeChatModelBackend(BaseBackend):
    """微信验证后端"""

    app_user_model: AbstractBaseUser = None

    def __init__(self, app_user_model: AbstractBaseUser, *args, **kwargs):
        self.app_user_model = app_user_model

    def authenticate(self, request=None, code=None, **kwargs):
        if kwargs["login_type"] != LoginType.WE_CHAT:
            return
        
        if self.app_user_model is None:
            raise ValueError("用户模型不能为`None`")
        ...
```
在继承 `BaseBackend` 的各个backend中, 都添加 `__init__` 函数来指定需要使用的相关配置  
如: 
-  `app_user_model` -> 覆盖默认设置中的 `AUTH_USER_MODEL`  
-  `app_config`-> 验证类需要的相关参数等  
-  其他字段  

### 创建通用backend
```python
class CommonBackend(BaseBackend):
    """通用验证后端"""

    app_user_model: AbstractBaseUser = None
    backend_class_list = [WeChatModelBackend, PhoneModelBackend]
    app_config: dict = None

    def validate_path(self, request) -> bool:
        """
        校验url路径; 
        true: 继续, 
        False: 跳过
        """
        raise NotImplementedError

    def authenticate(self, request, **kwargs):
        if not self.validate_path(request):
            return

        for backend_class in self.backend_class_list:
            backend = backend_class(self.app_user_model, self.app_config)
            user = backend.authenticate(request, **kwargs)

            # 验证类型错误的情况
            if user is None:
                continue

            return user
```
因为存在多个app使用多个backend的情况，而 `settings` 文件中的 `AUTHENTICATION_BACKENDS` 只能用来存放项目下每个app所使用的backend。即自定义的`backend`

`validate_path` 函数是为了解决不同app需要使用不同 `backend` 的情况.

如果你需要使用:
```python
def validate_path(request: Request, app_path: str) -> bool:
    # 匹配包含 app_path 作为独立路径段的 URL，区分大小写
    pattern = re.compile(rf"(^|/){app_path}($|/)", re.IGNORECASE)
    return bool(pattern.search(request.path))
```

### 创建 AppBackend
```python
class OneBackend(CommonBackend):
    app_user_model = UserModel

    def validate_path(self, request) -> bool:
        return validate_path(request, "app_one")
```
```python
class TwoBackend(CommonBackend):
    app_user_model = UserModel
    app_config: dict = settings.jwt_config

    def validate_path(self, request) -> bool:
        return validate_path(request, "app_two")
```
```python
class ThreeBackend(CommonBackend):
    app_user_model = UserModel
    # 只使用 `PhoneModelBackend`
    backend_class_list = [PhoneModelBackend]

    def validate_path(self, request) -> bool:
        return validate_path(request, "app_three")
```

## 2. 重写 `rest_framework_simplejwt` 的 `tokens`
重写 `AccessToken` 来让每个app使用各自的token配置  
主要是: `ACCESS_TOKEN_LIFETIME` 和 `REFRESH_TOKEN_LIFETIME` 这两个配置  

```python
class CustomAccessToken(AccessToken):
    """
    自定义的`Token`类
    以实现多app使用不同的Token生命周期
    """

    token_type = "access"

    def __init__(self, app_jwt_config: dict | None, *args, **kwargs) -> None:
        if app_jwt_config and (lifetime := app_jwt_config.get("ACCESS_TOKEN_LIFETIME")):
            self.lifetime = lifetime

        super().__init__(*args, **kwargs)

```
```python
class CustomRefreshToken(RefreshToken):
    """
    自定义的`RefreshToken`类
    以实现多app使用不同的 RefreshToken 生命周期
    """

    app_jwt_config: dict[str, str] | None = None
    # 使用自定义的AccessToken
    access_token_class = CustomAccessToken

    def __init__(self, app_jwt_config: dict | None, *args, **kwargs) -> None:
        if app_jwt_config and (lifetime := app_jwt_config.get("REFRESH_TOKEN_LIFETIME")):
            self.lifetime = lifetime
            self.app_jwt_config = app_jwt_config

        super().__init__(*args, **kwargs)

    @property
    def access_token(self) -> CustomAccessToken:
        """
        重写以适配自定义的AccessToken
        """
        access = self.access_token_class(self.app_jwt_config)
        access.set_exp(from_time=self.current_time)

        no_copy = self.no_copy_claims
        for claim, value in self.payload.items():
            if claim in no_copy:
                continue
            access[claim] = value

        return access

    @classmethod
    def for_user(cls: type[T], user: AuthUser, app_jwt_config: dict | None) -> T:  # noqa
        """
        这个重写 不包含 `BlacklistMixin` 的 `for_user`
        """
        user_id = getattr(user, api_settings.USER_ID_FIELD)
        if not isinstance(user_id, int):
            user_id = str(user_id)

        token = cls(app_jwt_config)
        token[api_settings.USER_ID_CLAIM] = user_id

        if api_settings.CHECK_REVOKE_TOKEN:
            token[api_settings.REVOKE_TOKEN_CLAIM] = get_md5_hash_password(user.password)

        return token
```

## 3. 重写TokenObtainPairSerializer
重写基础的TokenObtainPairSerializer
```python
class BaseTokenObtainPairSerializer(TokenObtainPairSerializer):
    # 使用自定义的`RefreshToken`
    token_class = CustomRefreshToken
    app_jwt_config: dict[str, str] | None = None

    @classmethod
    def get_token(cls, user: AuthUser) -> Token:
        """重写以适配自定义的token_class"""
        return cls.token_class.for_user(user, cls.app_jwt_config)
```

### 根据登录方式继续定义对应的 `Serializer`
或者在传参时指定`login_type` 并在 `get_serializer_class` 中指定对应的 `serializer`
或者使用 `动态Serializer(DynamicSerializerMixin)` 
```python
@extend_schema_serializer(exclude_fields=["login_type"])
class CommonCaptchaObtainPairSerializer(BaseTokenObtainPairSerializer):
    """手机+验证码"""

    phone = serializers.RegexField(PHONE_REGEX,help_text="手机号",write_only=True)
    code = serializers.CharField(max_length=6, help_text="验证码", write_only=True)
    login_type = serializers.CharField(default=LoginType.PHONE_CAPTCHA, write_only=True)

    class Meta:
        fields = ["phone", "code"]
```
```python
@extend_schema_serializer(exclude_fields=["login_type"])
class CommonWeChatObtainPairSerializer(BaseTokenObtainPairSerializer):
    """微信登录"""

    code = serializers.CharField(max_length=6, help_text="微信OAuthcode", write_only=True)
    login_type = serializers.CharField(default=LoginType.WE_CAHT, write_only=True)
    
    class Meta:
        fields = ["code"]
```

### 构建app的Serializer
```python
class PhoneCaptchaLoginSerializer(CommonCaptchaObtainPairSerializer):
    app_jwt_config = settings.APP_ONE_JWT # 注意导入所使用的配置
```

自此多app使用多backend进行注册的逻辑全部完成

## 4. 重写app的 `JWTAuthentication`
```python
class AppOneAuthentication(JWTAuthentication):
    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        # 同样覆盖默认的
        self.user_model = UserModel

    def authenticate(self, request: Request) -> Optional[Tuple[AuthUser, Token]]:
        if not validate_path(request, "app_one"):
            return None
        return super().authenticate(request)
```

同样使用 `validate_path` 来让其使用正确的 `JWTAuthentication`.   
`__init__` 函数中的 `UserModel` 需要与 app `Backend` 中的 `UserModel` 一致  

## settings 配置
```python
REST_FRAMEWORK={
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "./././AppOneAuthentication", # 实际的Authentication类地址
        "./././AppTwoAuthentication", # 实际的Authentication类地址
        "./././AppThreeAuthentication", # 实际的Authentication类地址
        ...
    ]
}

AUTHENTICATION_BACKENDS=[
    "./././OneBackend", # 实际的Backend类地址
    "./././TwoBackend", # 实际的Backend类地址
    "./././ThreeBackend", # 实际的Backend类地址
    ...
]

# app的其他相关配置
APP_ONE_JWT={}
```