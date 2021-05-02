summary: IceRock KMM onboarding #3
id: kmm-icerock-onboarding-3-ru
categories: lang-ru,kmm-icerock-onboarding,moko
status: published
authors: Andrey Kovalev, Aleksey Lobynya, Aleksey Mikhailov
tags: onboarding,kmm,ios,android,moko
feedback link: https://github.com/icerockdev/kmp-codelabs/issues

# IceRock KMM onboarding #3
## Пишем ViewModel
Duration: 5

Теперь перейдем к написанию общей логики нашей фичи. Предположим нам нужно написать типичную фичу авторизации. Экран в таком случае у нас будет не сложный: два поля ввода, для логина и пароля, и кнопка логина. Также нам понадобится лоадер, который мы будем показывать при отправлении запроса на сервер и сообщение об ошибке, на случай если что-то пойдет не так.

### Расположение ViewModel 

Так как ViewModel реализует общую логику приложения, она находится в общем коде приложения.
Для каждой фичи в mpp-library создается отдельный модуль, значит наша ViewModel авторизации будет находится в своем отдельном модуле feature/auth 

В новом проекте уже можно увидеть заготовку для нашей ViewModel авторизации

```kotlin
class AuthViewModel(
        override val eventsDispatcher: EventsDispatcher<EventsListener>,
) : ViewModel(), EventsDispatcherOwner<AuthViewModel.EventsListener> {

    interface EventsListener
}
```

Что такое eventsDispatcher? Это инструмент который служит для связи ViewModel и нативного экрана, если в ViewModel произошло событие, которое требует отображения на экране, либо некоторой нативной обработки мы уведомляем об этом нативную часть через eventsDispatcher. Для примера такими событиями могут быть: Показ диалога или переход на другой экран

Все что нам осталось это написать саму логику авторизации :)

### Пишем логику для AuthViewModel

Начнем с полей ввода: нам нужно две мутабельные лайвдаты для ввода логина и пароля

```kotlin
    val loginField: MutableLiveData<String> = MutableLiveData<String>("")
    val passwordField: MutableLiveData<String> = MutableLiveData<String>("")
```

Для этих полей ввода нам также потребуется валидация, ее мы пробросим через конструктор ViewModel, так как она может переиспользоваться на разных экранах. 
Для отображения ошибки валидации так-же создадим две лайв даты.

```kotlin
class AuthViewModel(
    override val eventsDispatcher: EventsDispatcher<EventsListener>,
    private val loginValidation: (String) -> StringDesc?,
    private val passwordValidation: (String) -> StringDesc?
) : ViewModel(), EventsDispatcherOwner<AuthViewModel.EventsListener> {

    val loginField: MutableLiveData<String> = MutableLiveData<String>("")
    val passwordField: MutableLiveData<String> = MutableLiveData<String>("")

    val loginValidationError: LiveData<StringDesc?> = loginField.map { login ->
        loginValidation(login)
    }
    val passwordValidationError: LiveData<StringDesc?> = passwordField.map { password ->
        passwordValidation(password)
    }
    
    interface EventsListener
}
```

Для удобства имеет смысл выделять все валидаторы в отдельный класс Validation

```kotlin
class AuthViewModel(
    override val eventsDispatcher: EventsDispatcher<EventsListener>,
    private val validation: Validation
) : ViewModel(), EventsDispatcherOwner<AuthViewModel.EventsListener> {
    
    ...
    
    val loginValidationError: LiveData<StringDesc?> = loginField.map { login ->
        validation.validateLogin(login)
    }
    val passwordValidationError: LiveData<StringDesc?> = passwordField.map { password ->
        validation.validatePassword(password)
    }
```

После того как пользователдь ввел свои логин и пароль, нам потребуется обработать нажатие кнопки логина. Для этого напишем функцию onLoginTap.
При нажатии кнопки логина, мы должны отправить на сервер запрос с необходимыми данными. 

Но в перую очередь нам нужно показать пользователю прогресс бар чтобы он не заскучал в ожидании ответа.
Добавим приватную MutableLiveData для флага показа лоадера, и публичную LiveData которую сможет получить натив. 

При нажатии кнопки запустим короутину и установим флаг загрузки true
```kotlin
    val _isLoading = MutableLiveData<Boolean>(false)
    val isLoading: LiveData<Boolean> = _isLoading.readOnly()

    fun onLoginTap() {
        viewModelScope.launch {
            _isLoading.value = true
        }
    }
```

Далее нам требуется отправить запрос на сервер, этим занимается не сама ViewModel а связанный с эти функционалом репозиторий. Котороый нам нужно пробросить в ViewModel через параметры конструктора
```kotlin
    private val repository: AuthRepository
```

Сам вызов suspend функкции репозитория нам нужно обернуть в try-catch, так как нам может вернуться Exception. Например если пользователь ввел неверный логин/пароль, у пользователя пропал интернет или если сервер просто решил отдохнуть.

Для отображения произошедшей ошибки нам и пригодится eventsDispatcher. Добавим в EventsListener нашей ViewModel обработку нового события showError
```kotlin
    interface EventsListener {
        fun showError(error: StringDesc)
    }
```

Также нам потребуется мапер, который сможет из полученого исключения сделать красивое сообщение об ошибке, добавим его через конструктор нашей ViewModel
```kotlin
    private val errorMapper: (Exception) -> StringDesc
```

Наконец обработаем ошибку и не забудем убрать прогресс бар не зависимо от того какой результат мы получили от репозитория
```kotlin
    try {
        repository.login(loginField.value, passwordField.value)
    } catch (exception: Exception) {
        eventsDispatcher.dispatchEvent { showError(errorMapper(exception)) }
    } finally {
        _isLoading.value = false
    }
```
Все что осталось это добавить переход на следующий экран при успешном логине. Для этого добавим обработчик события перехода на main экран в EventsListener
```kotlin
    interface EventsListener {
        fun showError(error: StringDesc)
        fun routeToMain()
    }
```

И вызов этого события через eventsDispatcher в блоке try
```kotlin
    try {
        repository.login(loginField.value, passwordField.value)
        eventsDispatcher.dispatchEvent { routeToMain() }
    }
```

На этом наша AuthViewModel фактически готова к использованию. Хотя кое-что в ней еще можно улучшить

### Принцип связи общей и нативной частей

В наших проектах используется следующий принцип:
- Вся общая логика разбита на фичи и находится в mpp-library/feature
- Нативная часть андроида приложения находится в app, внутри не бьется нв модули но фичи разбиты по разным пакетам, аналогично разбиению в mpp-library
- Нативная часть ios приложения находится в ios-app
- Важную часть в связи нативного и общего кода играет SharedFactory, 
  она расположена в mpp-library/src/commonMain и содержит в себе фабрики отдельных фичей, репозитории
- Реализаций фабрик фичей и репозиториев необходимых для их работы также расположены в mpp-library/src/commonMain,
каждая фабрика фичи умеет создавать все необходимые ViewModel для своей фичи
  
На андроид проекте мы помещаем SharedFactory в AppComponent
```kotlin
object AppComponent {
    lateinit var factory: SharedFactory
}
```
и инициализируем в методе onCreate нашей Application, после этого обращаемся к ней тогда, когда нам нужно создать какую-либо ViewModel 

### Навигация
#### Android

Для навигации в андроид приложении мы используем NavController.

Есть одна RootActivity. А все экраны приложения представляют собой фрагменты, навигация между которыми реализована через NavController

Для реализации в gradle андроид app нужно добавить
```
    implementation(Deps.Libs.Android.navigatonFragment)
    implementation(Deps.Libs.Android.navigatonUI)
```
Реализуем простую RootActivity
```kotlin
class RootActivity : AppCompatActivity() {

    private lateinit var navController: NavController
    private lateinit var binding: ActivityRootBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRootBinding.inflate(LayoutInflater.from(this))
        setContentView(binding.root)
        initNavController()
    }

    private fun initNavController() {
        val host =
                supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navController = host.navController
    }
}

```
и простую верстку 
```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/root_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <fragment
        android:id="@+id/nav_host_fragment"
        android:name="androidx.navigation.fragment.NavHostFragment"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        app:defaultNavHost="true"
        app:navGraph="@navigation/root_navigation" />
</FrameLayout>
```
Далее для переходов между фрагментами будем использовать сгенерированый класс Directions и navController фрагмента. Например
```kotlin
   val dir = AuthFragmentDirections.actionAuthToRequestResetPassword()
   navController?.navigate(dir)
```

### Создание нативного экрана авторизации
Пришло время написать нативную реализацию экрана.

Сам экран представляет из себя фрагмент, который мы прибиндим к нашей AuthViewModel, для верстки нам понадобится два поля ввода и сообщения об шибках под ними

кнопка для логина

и прогресс бар на время загрузки

Теперь, когда у нас есть готовая верстка перейдем к созданию самого фрагмента
```kotlin
class AuthFragment :
    MvvmEventsFragment<FragmentAuthBinding, AuthViewModel, AuthViewModel.EventsListener>(),
    AuthViewModel.EventsListener {
```
класс AuthFragment наследуется от MvvmEventsFragment из dev.icerock.moko:mvvm-viewbinding в дженерике мы указываем ему сгенерированный класс верстки, класс вьюмодели, и класс лстенера для eventDispatcher
MvvmEventsFragment сам подпишется на eventDispatcher вьюмодели, в отличие от MvvmFragment
При наследовании от MvvmEventsFragment нам нужно реализовать 
- viewModelClass указать класс используемой viewModel
- viewBindingInflate создать экземпляр сгенерированного из верстки класса FragmentAuthBinding
- viewModelFactory реализовать фэктори для создания необходимой ViewModel
```kotlin
    override val viewModelClass: Class<AuthViewModel> = AuthViewModel::class.java

    override fun viewBindingInflate(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): FragmentAuthBinding {
        return FragmentAuthBinding.inflate(layoutInflater, container, false)
    }

    override fun viewModelFactory(): ViewModelProvider.Factory = ViewModelFactory {
        AppComponent.factory.authFactory.createAuthViewModel(eventsDispatcherOnMain())
    }
```
Помимо этого нужно реализовать функции интерфейса AuthViewModel.EventsListener от которого мы отнаследовались, что-бы фрагмент мог реагировать на события которые будет отправлять viewModel



### Дружим ViewController и ViewModel

// Описать создание VM через фабрику, добавить базовый MVVM контроллер, допилить AuthController, сделать пустой биндинг и перейти к описанию


###

### Обработка действий пользователя и передача данных от натива к общей части

// Заводим филды во вьюмодели, публичный метод для обработчика кнопки с принтом в консоль, показываем, как биндиться к филдам, биндим доступность кнопки, биндим текст лейбла к лайвдате


### 


### Реализация логики и передача событий и команд от общей части к нативной

// Дополняем EventListener для VM авторизации, в ней роут на новости и showError

ПОКАЗАТЬ ЧТО СБОРКА ЛОМАЕТСЯ, объяснить, как влияют правки общие на соседнюю платформу. Замокать без репозитория на уровне VM проверку логина/пароля.




### Локализация и ресурсы

// Рассказать про моко-ресурсы, завести табличку, добавить строк, добавить интерфейс строк в VM, пробросить при реализации, изменить текста ошибок на StringDesc локализованный.


### Сохранение в локальное хранилище. 

// Добавить логику запоминания токена в локальном хранилище. Показать, как с сеттингсами работать. 


### 


### Построение экранов

// Раздел для описания разных подходов к вёрстке экранов


#### Нативная вёрстка

// Сослаться на авторизацию, объяснить про вёрстку на чистом нативе с биндингами


### Обработка ошибок

// моко-еррорс
