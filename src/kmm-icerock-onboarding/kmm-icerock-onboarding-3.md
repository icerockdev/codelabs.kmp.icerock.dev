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

Теперь перейдем к написанию общей логики нашей фичи. Предположим нам нужно написать типичную фичу авторизации. Экран в
таком случае у нас будет не сложный: два поля ввода, для логина и пароля, и кнопка логина. Также нам понадобится лоадер,
который мы будем показывать при отправлении запроса на сервер и сообщение об ошибке, на случай если что-то пойдет не
так.

### Расположение ViewModel

Так как ViewModel реализует общую логику приложения, она находится в общем коде приложения. Для каждой фичи в
mpp-library создается отдельный модуль, значит наша ViewModel авторизации будет находится в своем отдельном модуле
feature/auth

В новом проекте уже можно увидеть заготовку для нашей ViewModel авторизации

```kotlin
class AuthViewModel(
        override val eventsDispatcher: EventsDispatcher<EventsListener>,
) : ViewModel(), EventsDispatcherOwner<AuthViewModel.EventsListener> {

    interface EventsListener
}
```

Что такое eventsDispatcher? Это инструмент который служит для связи ViewModel и нативного экрана, если в ViewModel
произошло событие, которое требует отображения на экране, либо некоторой нативной обработки мы уведомляем об этом
нативную часть через eventsDispatcher. Для примера такими событиями могут быть: Показ диалога или переход на другой
экран

Все что нам осталось это написать саму логику авторизации :)

### Пишем логику для AuthViewModel

Начнем с полей ввода: нам нужно две мутабельные лайвдаты для ввода логина и пароля

```kotlin
val loginField: MutableLiveData<String> = MutableLiveData<String>("")
val passwordField: MutableLiveData<String> = MutableLiveData<String>("")
```

Для этих полей ввода нам также потребуется валидация, ее мы пробросим через конструктор ViewModel, так как она может
переиспользоваться на разных экранах. Для отображения ошибки валидации так-же создадим две лайв даты.

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

После того как пользователдь ввел свои логин и пароль, нам потребуется обработать нажатие кнопки логина. Для этого
напишем функцию onLoginTap. При нажатии кнопки логина, мы должны отправить на сервер запрос с необходимыми данными.

Но в перую очередь нам нужно показать пользователю прогресс бар чтобы он не заскучал в ожидании ответа. Добавим
приватную MutableLiveData для флага показа лоадера, и публичную LiveData которую сможет получить натив.

Также добавим лайвдату isButtonEnabled в котрой будет отображен флаг, что кнопка логина доступна к нажатию. Кнопка
доступна если все поля корректны и нет активного запроса

```kotlin
val _isLoading = MutableLiveData<Boolean>(false)
val isLoading: LiveData<Boolean> = _isLoading.readOnly()

val isButtonEnabled: LiveData<Boolean> = listOf(
        loginValidationError.map { it == null },
        passwordValidationError.map { it == null },
        isLoading.map { it.not() }
).all(true)
```

При нажатии кнопки запустим короутину и установим флаг загрузки true

```kotlin
fun onLoginTap() {
    viewModelScope.launch {
        _isLoading.value = true
    }
}
```

Далее нам требуется отправить запрос на сервер, этим занимается не сама ViewModel а связанный с эти функционалом
репозиторий. Котороый нам нужно пробросить в ViewModel через параметры конструктора

```kotlin
private val repository: AuthRepository
```

Сам вызов suspend функкции репозитория нам нужно обернуть в try-catch, так как нам может вернуться Exception. Например
если пользователь ввел неверный логин/пароль, у пользователя пропал интернет или если сервер просто решил отдохнуть.

Для отображения произошедшей ошибки нам и пригодится eventsDispatcher. Добавим в EventsListener нашей ViewModel
обработку нового события showError

```kotlin
interface EventsListener {
    fun showError(error: StringDesc)
}
```

Также нам потребуется мапер, который сможет из полученого исключения сделать красивое сообщение об ошибке, добавим его
через конструктор нашей ViewModel

```kotlin
    private val errorMapper: (Exception) -> StringDesc
```

Наконец обработаем ошибку и не забудем убрать прогресс бар не зависимо от того какой результат мы получили от
репозитория

```kotlin
try {
    repository.login(loginField.value, passwordField.value)
} catch (exception: Exception) {
    eventsDispatcher.dispatchEvent { showError(errorMapper(exception)) }
} finally {
    _isLoading.value = false
}
```

Все что осталось это добавить переход на следующий экран при успешном логине. Для этого добавим обработчик события
перехода на main экран в EventsListener

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
- Нативная часть андроида приложения находится в app, внутри не бьется нв модули но фичи разбиты по разным пакетам,
  аналогично разбиению в mpp-library
- Нативная часть ios приложения находится в ios-app
- Важную часть в связи нативного и общего кода играет SharedFactory, она расположена в mpp-library/src/commonMain и
  содержит в себе фабрики отдельных фичей, репозитории
- Реализаций фабрик фичей и репозиториев необходимых для их работы также расположены в mpp-library/src/commonMain,
  каждая фабрика фичи умеет создавать все необходимые ViewModel для своей фичи

На андроид проекте мы помещаем SharedFactory в AppComponent

```kotlin
object AppComponent {
    lateinit var factory: SharedFactory
}
```

и инициализируем в методе onCreate нашей Application, после этого обращаемся к ней тогда, когда нам нужно создать
какую-либо ViewModel

### Создание нативного экрана авторизации

Пришло время написать нативную реализацию экрана.

Сам экран представляет из себя фрагмент, который мы прибиндим к нашей AuthViewModel, для верстки нам понадобится два
поля ввода и сообщения об ошибках под ними

```xml

<com.google.android.material.textfield.TextInputEditText
        android:id="@+id/login"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginHorizontal="16dp"
        android:layout_marginTop="160dp"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"/>

<androidx.appcompat.widget.AppCompatTextView
android:id="@+id/loginValidation"
android:layout_width="0dp"
android:layout_height="wrap_content"
android:textAppearance="?textAppearanceBody2"
android:textColor="?colorAccent"
app:layout_constraintTop_toBottomOf="@id/login"
app:layout_constraintStart_toStartOf="@id/login"
app:layout_constraintEnd_toEndOf="@id/login"/>

<com.google.android.material.textfield.TextInputEditText
android:id="@+id/password"
android:layout_marginHorizontal="16dp"
android:layout_width="0dp"
android:layout_height="wrap_content"
android:layout_marginTop="16dp"
app:layout_constraintEnd_toEndOf="parent"
app:layout_constraintStart_toStartOf="parent"
app:layout_constraintTop_toBottomOf="@id/login"/>

<androidx.appcompat.widget.AppCompatTextView
android:id="@+id/passwordValidation"
android:layout_width="0dp"
android:layout_height="wrap_content"
android:textAppearance="?textAppearanceBody2"
android:textColor="?colorAccent"
app:layout_constraintTop_toBottomOf="@id/password"
app:layout_constraintStart_toStartOf="@id/password"
app:layout_constraintEnd_toEndOf="@id/password"/>
```

кнопка для логина

```xml

<androidx.appcompat.widget.AppCompatButton
        android:id="@+id/button_login"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_margin="40dp"
        android:text="@string/auth_button_enter"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        tools:text="Войти"/>
```

и прогресс бар на время загрузки

```xml

<ProgressBar
        android:id="@+id/loading"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"/>
```

Теперь перейдем к созданию самого фрагмента

```kotlin
class AuthFragment :
        MvvmEventsFragment<FragmentAuthBinding, AuthViewModel, AuthViewModel.EventsListener>(),
        AuthViewModel.EventsListener {
```

класс AuthFragment наследуется от MvvmEventsFragment из dev.icerock.moko:mvvm-viewbinding в дженерике мы указываем ему
сгенерированный класс верстки, класс вьюмодели, и класс лстенера для eventDispatcher MvvmEventsFragment сам подпишется
на eventDispatcher вьюмодели, в отличие от MvvmFragment При наследовании от MvvmEventsFragment нам нужно реализовать

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

Помимо этого нужно реализовать функции интерфейса AuthViewModel.EventsListener от которого мы отнаследовались, что-бы
фрагмент мог реагировать на события которые будет отправлять viewModel Так как никаких других фрагментов для навигации
нет просто покажем тост который покажет нам, что ивент получен

```kotlin
    override fun showError(error: StringDesc) {
    context?.let { context ->
        AlertDialog.Builder(context)
                .setMessage(error.toString(context))
                .setCancelable(true)
                .show()
    }
}

override fun routeToMain() {
    Toast.makeText(requireContext(), "Успех!", Toast.LENGTH_SHORT).show()
}
```

### Байндинг фрагмента к ViewModel

Теперь нам нужно связать наши поля и кнопки с AuthViewModel. Для этого в методе onViewCreated мы можем использовать уже
заранее написаные методы bind

Привязываем мутабл лайвдаты логина и пароля к view

```kotlin
    viewModel.loginField.bindTwoWayToEditTextText(viewLifecycleOwner, binding.login)
viewModel.passwordField.bindTwoWayToEditTextText(viewLifecycleOwner, binding.login)
```

Привязываем лайвдаты ошибок к соответствующим TextView

```kotlin
    val context = requireContext()
viewModel.loginValidationError.bind(viewLifecycleOwner) {
    binding.loginValidation.text = it?.toString(context)
}
viewModel.passwordValidationError.bind(viewLifecycleOwner) {
    binding.passwordValidation.text = it?.toString(context)
}
```

и осталось привязать видимость прогресс бара

```kotlin
    viewModel.isLoading.bindToViewVisibleOrGone(viewLifecycleOwner, binding.loading)
viewModel.isButtonEnabled.bindToViewEnabled(viewLifecycleOwner, binding.buttonLogin)
```

Теперь наш фрагмент может отображать данные из viewModel, и передавать ей то что введено в поля ввода. Осталось добавить
листенер для кнопки логина

```kotlin
    binding.buttonLogin.setOnClickListener {
    viewModel.onLoginTap()
}
```

На iOS также SharedFactory помещается в AppComponent. Для этого в классе AppComponent есть статическое поле factory:

```swift
class AppComponent {
    static var factory: SharedFactory!
}
```

В AppDelegate в методе didFinishLaunchingWithOptions создаём SharedFactory с передачей необходимых параметров и кладём
её в поле factory у AppComponent.

```swift
  AppComponent.factory = SharedFactory(
      settings: AppleSettings(delegate: UserDefaults.standard),
      antilog: DebugAntilog(defaultTag: "MPP"),
      baseUrl: "https://newsapi.org/v2/"
  )
```

### Навигация

#### Android

Для навигации в андроид приложении мы используем NavController.

Есть одна RootActivity. А все экраны приложения представляют собой фрагменты, навигация между которыми реализована через
NavController

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

и простую верстку в которой помещаем NavHostFragment в контейнер экрана

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
            app:navGraph="@navigation/root_navigation"/>
</FrameLayout>
```

После чего нам остается описать навигацию в root_navigation.xml, в данный момент она будет состоять из одного фрагмента,
который и является стартовым

```xml
<?xml version="1.0" encoding="utf-8"?>
<navigation xmlns:android="http://schemas.android.com/apk/res/android"
            xmlns:app="http://schemas.android.com/apk/res-auto"
            android:id="@+id/root_navigation"
            app:startDestination="@id/auth">

    <fragment
            android:id="@+id/auth"
            android:name="org.example.app.features.auth.AuthFragment"/>
</navigation>
```

Далее для переходов между фрагментами будем использовать сгенерированый класс Directions и navController фрагмента.
Например

```kotlin
   val dir = AuthFragmentDirections.actionAuthToRequestResetPassword()
navController?.navigate(dir)
```

#### iOS

В основе навигации лежат координаторы. Каждый координатор покрывает логически связанный блок функционала, который чаще
всего состоит из нескольких экранов. При этом между собой они независимы и отвечают только за цепочку переходов только
внутри себя. Также имеют возможность получать настройку действия, которое должно быть выполнено после завершения блока
ответственности координатора.

Например.

Предположим, что у нас есть приложение, в котором имеется авторизация, просмотр списка новостей, с возможностью перехода
к детальному виду каждой новости, а со списка новостей можно попасть в раздел настроек для конфигурации отображения
новостей. Это разобьётся на 4 координатора:

1. AppCoordinator

- Стартовый координатор.
- Всегда является первой входной точкой, определяет, куда должен выполниться дальнейший переход при запуске приложения
- Если юзер не авторизован - запустит координатор авторизации и в качестве completionHandler-а укажет ему переход на
  новости в случае успешной авторизации
- Если юзер уже авторизован - запустит координатор просмотра новостей

2. AuthCoordinator

- Запустит процесс авторизации
- Будет совершать переходы по всем требуемым шагам - например ввод логина/пароля, смс-кода, установки никнейма и т.п.
- По итогу успешной авторизации вызовет переданный ему на вход completionHandler.

3. NewsCoordinator

- Отвечает за показ списка новостей
- Реализовывает переход в детали конкретной новости внутри этого же координатора
- При переходе в настройки создаёт координатор настроек, с качестве completionHandler-а может передать ему логику
  обновления своего списка новостей. Если в настройках изменились параметры
- обновляет список

4. SettingsCoordinator

- Отвечает за работу с экраном настроек
- При завершении работы и применении настроек вызывает completion, чтобы новости обновились

Именно координаторы реализуют интерфейс EventListener-ов вьюмоделей, о которых будет чуть ниже. Так как вызов переходов
завязан на бизнес-логику приложения, то инициатором этих переходов являются именно вьюмодели. Поэтому координаторы
выполняют связующую роль между тем, что происходит в логике приложений и тем, как это должно отражаться пользователю.

Чтобы работать с координаторами было проще, используется базовый класс, от которого наследуются остальные. Он называется
BaseCoordinator и лежит в директории ios-app/src/Common/Coordinator. Требование к координатору - это реализация
протокола Coordinator, который лежит рядом в той же директории:

```swift
protocol Coordinator: class {
    var completionHandler: (()->())? { get }
    func start()
    func clear()
}
```

completionHandler - коллбэк, который вызывается при завершении работы координатора (например закончили флоу авторизации)
start - метод старта координатора. Внутри него координатор должен определить, какой экран у него должен быть стартовым,
создать его и отобразить clear - метод очистки координатора. В нём необходимо очистить дочерние координаторы.

Всё это есть в базовом координаторе. Даже больше. Пройдёмся по основным важным моментам BaseCoordinator-а.

Для инициализации ему требуется передать UIWindow и SharedFactory. UIWindow требуется для отображения контроллеров,
диалогов, а SharedFactory позволит создавать вьюмодели для контроллеров.

В поле childCoordinators хранится массив дочерних координаторов. Они нужны для того, чтобы иметь возможность при
завершении работы координатора корректно очистить их и избежать утечек памяти.

Также имеются два коллбэка - completionHandler и clearHandler. Первый нужен для того, чтобы указать необходимую
дополнительную логику, которая должна выполниться, когда координатор сообщит о том, что он выполнил свою часть логики. А
второй необходим для обработки события о том, что координатор очищен.

Чтобы избежать ошибок в построении связей и переходах в базовом координаторе заведены следующие публичные методы:

- addDependency - этот метод используется для того, чтобы добавить текущему координатору в зависимость новый
  координатор. Он проверит есть ли уже координатор такого типа в зависимостях, а при отсутствии - выполнит добавление и
  подстрахует с добавлением вызова удаления зависимости.
- beginInNewNavigation - принимает UIViewController, создаёт с ним новый UINavigationController и запускает новую
  цепочку навигации, устанавливая этот контроллер навигации как рутовый в UIWindow.
- beginInExistNavigation - принимает UIViewController, запоминает в качестве предыдущего контроллера тот, который сейчас
  последний в текущем UINavigationController. Это нужно для того, чтобы при очистке координатора выполнить переход к
  тому контроллеру, с которого мы пришли на этот координатор.
- currentViewController - возвращает текущий контроллер координатора

### Создание нативного экрана авторизации

#### Android

Пришло время написать нативную реализацию экрана.

Сам экран представляет из себя фрагмент, который мы прибиндим к нашей AuthViewModel, для верстки нам понадобится два
поля ввода и сообщения об шибках под ними

кнопка для логина

и прогресс бар на время загрузки

Теперь, когда у нас есть готовая верстка перейдем к созданию самого фрагмента

```kotlin
class AuthFragment :
        MvvmEventsFragment<FragmentAuthBinding, AuthViewModel, AuthViewModel.EventsListener>(),
        AuthViewModel.EventsListener {
```

класс AuthFragment наследуется от MvvmEventsFragment из dev.icerock.moko:mvvm-viewbinding в дженерике мы указываем ему
сгенерированный класс верстки, класс вьюмодели, и класс лстенера для eventDispatcher MvvmEventsFragment сам подпишется
на eventDispatcher вьюмодели, в отличие от MvvmFragment При наследовании от MvvmEventsFragment нам нужно реализовать

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

#### iOS

Duration: 20

Как правило фичи в нативном проекте соответствуют аналогичным фичам в мультиплатформенном проекте. Мы начнём с простого
- с авторизации. Если открыть в AndroidStudio проект и зайти в папку mpp-library, то мы увидим в ней папку features -
  это и есть наши фичи. В ней уже даже есть auth. Сделаем для неё нативную реализацию.

Сначала наметим структуру папок в нашем проекте. Внутри src создадим папку Features, а в ней - Auth. Для авторизации нам
понадобится контроллер и координатор. Чтобы всё не смешивалось в кучу (а в боевых проектах в фиче сильно больше файлов
будет) сразу научимся группировать по папкам содержимое фичи. Заведём директории под контроллеры, координаторы и сами
классы. Получится следующая структура:

Вёрстку мы ведём через xib-файлы. Обработчики действий и связи настраиваются через IBActions и IBOutlets. Кастомизация
UI-элементов стилями конкретного проекта уже происходит кодом. Здесь мы не будем уходить глубоко в кастомизацию, поэтому
контроллер у нас будет довольно простой - лейбл, пара полей для ввода логина и пароля и кнопка входа.

На вкус и цвет фломастеры бывают разные, можешь отверстать экран по-своему. Основные требования - Label-заголовок, два
UITextField и одна кнопка UIButton. Что-то типа такого:

И класс у неё также пока очень простой:

```swift

import UIKit

class AuthViewController: UIViewController {

    // MARK:** - Outlets**

    @IBOutlet private var welcomeLabel: UILabel!
    @IBOutlet private var loginTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var loginButton: UIButton!

    // MARK:** - Actions**

    @IBAction func onLoginButtonAction(_ sender: UIButton) {
        // On button Action
    }
}

Далее создадим координатор:

class AuthCoordinator: BaseCoordinator {

    // MARK:** - Overrides**

    override func start() {
        let vc = AuthViewController()
        self.window.rootViewController = vc
    }
}
```

Он также несложный. Состоит пока из одного метода start, который помещает на window наш созданный AuthViewController.

И чтобы это всё работало изменяем координатор приложения. Теперь нам там нужно убрать тот тестовый зелёный экран и
запустить флоу координатора авторизации:

```swift

class AppCoordinator: BaseCoordinator {

    // MARK:** - Overrides**
    override func start() {
        routeToAuth()
    }

    private func routeToAuth() {

        // 1. Создаём координатор авторизации
        let authCoordinator = AuthCoordinator(window: self.window)

        // 2. Обязательно указываем в completionHandler удаление зависимости.
        // Также добавляем сразу заготовку под будущий переход к новостям при успешной авторизации

        authCoordinator.completionHandler = { [weak self] in
            self?.removeDependency(authCoordinator)
            self?.routeToNewsList()
        }

        // 3. Добавляем новый координатор в зависимость к текущему
        addDependency(authCoordinator)

        // 4. Вызываем у него старт
        authCoordinator.start()
    }

    private func routeToNewsList() {
        // Здесь будет переход к новостям
    }
}

```

Собираем, запускаем и видим уже не тот недохромакей, а контроллер авторизации, который только что сверстали.
Комментариями к коду подписаны основные шаги в создании нового координатора. Важным моментом является удаление
зависимости в completion-блоке создаваемого координатора, чтобы не плодились утечки памяти.

Также полезно будет указать сразу заглушку для метода перехода к новостям. Пусть он пока и пустой, зато сразу получаем
более общую картину, где какие вызовы будут в будущем.

Окей. Мы создали контроллер, создали координатор. Даже перешли на экран авторизации. Но как будет реализовываться
логика? Где брать вьюмодель? Как она узнает, что юзер что-то ввёл? Как координатор поймёт, что ему нужно вызывать
completion и переходить к новостям, ведь контроллер, который мы создали, даже не знает о том, что какой-то там
координатор существует?

Чтобы понять, как это работает перейдём к созданию вьюмодели и передаче её контроллеру.

### Реализация логики и передача событий и команд от общей части к нативной

// Дополняем EventListener для VM авторизации, в ней роут на новости и showError

ПОКАЗАТЬ ЧТО СБОРКА ЛОМАЕТСЯ, объяснить, как влияют правки общие на соседнюю платформу. Замокать без репозитория на
уровне VM проверку логина/пароля.

### Локализация и ресурсы

// Рассказать про моко-ресурсы, завести табличку, добавить строк, добавить интерфейс строк в VM, пробросить при
реализации, изменить текста ошибок на StringDesc локализованный.

### Сохранение в локальное хранилище.

// Добавить логику запоминания токена в локальном хранилище. Показать, как с сеттингсами работать.

###        

### Построение экранов

// Раздел для описания разных подходов к вёрстке экранов

#### Нативная вёрстка

// Сослаться на авторизацию, объяснить про вёрстку на чистом нативе с биндингами

### Обработка ошибок

// моко-еррорс