summary: MOKO Widgets #4 - действия на экранах
id: moko-widgets-4
categories: moko
environments: kotlin-mobile-mpp
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Mikhailov <am@icerock.dev>

# MOKO Widgets #4 - screen actions
## Вводная
Duration: 5

Урок является продолжением [MOKO Widgets #3 - styles](https://codelabs.kmp.icerock.dev/codelabs/moko-widgets-3/). Для выполнения данного урока нужно иметь проект, полученный в результате выполнения предыдущего урока.

Результатом прошлого урока было приложение с навигацией и стилизацией экранов.

На этом уроке мы добавим различные действия, происходящие на экране:
- Открытие ссылки в браузере;
- Показ сообщения;
- Показ диалога с обработкой ответа пользователя;
- Открытие системного экрана с обработкой результата.

## Открытие ссылки
Duration: 2

Для примера добавим на экран ввода телефона кнопку `GitHub`, по нажатию на которую должен открыться гитхаб `moko-widgets`. 

### Добавление кнопки
Чтобы это реализовать сначала добавим кнопку на экран:

`mpp-library/src/commonMain/kotlin/org/example/mpp/auth/InputPhoneScreen.kt`:
```kotlin
class InputPhoneScreen(
    ...
) : ... {
    ...

    override fun createContentWidget() = with(theme) {
        ...

        constraint(size = WidgetSize.AsParent) {
            ...

            val githubButton = +button(
                size = WidgetSize.WrapContent,
                content = ButtonWidget.Content.Text(Value.data("GitHub".desc())),
                onTap = ::onGitHubPressed
            )

            constraints {
                ...

                githubButton centerXToCenterX root
                githubButton topToTop root.safeArea offset 16
            }
        }
    }

    private fun onGitHubPressed() {
        TODO()
    }

    ...
}
```

### Реализация обработчика кнопки
Теперь остается добавить реакцию на нажатие кнопки. Нам нужно открыть url в браузере.
На android для открытия URL нам нужен context (любой экран приложения по сути), а на iOS можем из любого места приложения вызвать нужный код. Чтобы действие было доступно из общего кода реализуем специальную `expect` экстеншен функцию к классу `Screen` (это даст нам  доступ до context на android).

`mpp-library/src/commonMain/kotlin/org/example/mpp/ScreenExt.kt`:
```kotlin
expect fun Screen<*>.openUrl(url: String)
```

Android - `mpp-library/src/androidMain/kotlin/org/example/mpp/ScreenExt.kt`:
```kotlin
actual fun Screen<*>.openUrl(url: String) {
    val context = requireContext()
    val openIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    if (openIntent.resolveActivity(context.packageManager) != null) {
        context.startActivity(openIntent)
    }
}
```

Positive
: так как `Screen` это `Fragment` на android, то `this` в этой функции имеет все возможности `Fragment` - включая и `requireContext()`.

iOS - `mpp-library/src/iosMain/kotlin/org/example/mpp/ScreenExt.kt`:
```kotlin
actual fun Screen<*>.openUrl(url: String) {
    UIApplication.sharedApplication.openURL(NSURL.URLWithString(url)!!)
}
```

Positive
: для добавления `iosMain` в данном шаблоне доступно использование symlinks, подробнее было указано в [codelab](https://codelabs.kmp.icerock.dev/codelabs/kmp-mobile-from-zero/index.html?index=..%2F..index#4).

Остается в обработчике кнопки вызвать наш новый метод:

`mpp-library/src/commonMain/kotlin/org/example/mpp/auth/InputPhoneScreen.kt`:
```kotlin
class InputPhoneScreen(
    ...
) : ... {
    ...

    private fun onGitHubPressed() {
        openUrl("https://github.com/icerockdev/moko-widgets")
    }

    ...
}
```

### Тестирование
Теперь можно запустить приложение (как Android так и iOS) и убедиться что открытие ссылки полностью работает.


## Показ сообщения
Duration: 2


## Показ диалога с обработкой результата
Duration: 2


## Открытие системного экрана
Duration: 2

