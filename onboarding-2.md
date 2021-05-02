summary: MOKO Widgets #2 - роутинг
id: moko-onboarfing-2
categories: moko
environments: kotlin-mobile-mpp
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Lobynya <alobynya@icerockdev.com>

# MOKO Onboarding #2 - ViewModel
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

### Дружим ViewController и ViewModel

// Описать создание VM через фабрику, добавить базовый MVVM контроллер, допилить AuthController, сделать пустой биндинг и перейти к описанию


### 


### Принцип связи общей и нативной частей


// Пояснить, что есть что и где находится в общих чертах, дальше перейти к деталям


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
