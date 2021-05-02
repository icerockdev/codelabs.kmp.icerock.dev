summary: MOKO Widgets #5 - собственные фабрики виджетов
id: moko-widgets-5-ru
categories: lang-ru,moko,moko-widgets
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Mikhailov <am@icerock.dev>

# MOKO Widgets #5 - custom ViewFactory
## Вводная
Duration: 5

Урок является продолжением [MOKO Widgets #4 - screen actions](https://codelabs.kmp.icerock.dev/codelabs/moko-widgets-4/). Для выполнения данного урока нужно иметь проект, полученный в результате выполнения предыдущего урока.

Результатом прошлого урока было приложение с навигацией, стилизацией экранов и различными действиями на экранах.

На этом уроке мы реализуем собственные фабрики виджетов на примере поля ввода телефона и кода.

## Своя фабрика InputWidget полностью в Kotlin
Duration: 15

### Common code
`mpp-library/src/commonMain/kotlin/org/example/mpp/PhoneInputViewFactory.kt`:
```kotlin
expect class PhoneInputViewFactory() : ViewFactory<InputWidget<out WidgetSize>>
```

### Android code
`mpp-library/src/androidMain/kotlin/org/example/mpp/PhoneInputViewFactory.kt`:
```kotlin
actual class PhoneInputViewFactory : ViewFactory<InputWidget<out WidgetSize>> {
    override fun <WS : WidgetSize> build(
        widget: InputWidget<out WidgetSize>,
        size: WS,
        viewFactoryContext: ViewFactoryContext
    ): ViewBundle<WS> {
        val context = viewFactoryContext.androidContext
        val lifecycleOwner = viewFactoryContext.lifecycleOwner

        val editText = EditText(context).apply {
            id = widget.id.androidId

            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )

            widget.inputType?.also { applyInputType(it) }

            setOnFocusChangeListener { _, hasFocus ->
                if (!hasFocus) widget.field.validate()
            }
            addTextChangedListener(object : TextWatcher {
                override fun afterTextChanged(s: Editable?) {}

                override fun beforeTextChanged(
                    s: CharSequence?,
                    start: Int,
                    count: Int,
                    after: Int
                ) {
                }

                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                    if (s == null) return

                    widget.field.data.value = s.toString()
                }
            })
        }

        widget.field.data.bind(lifecycleOwner) { data ->
            if (editText.text?.toString() == data) return@bind

            editText.setText(data)
        }

        widget.label.bind(lifecycleOwner) { editText.hint = it?.toString(context) }
        widget.enabled?.bind(lifecycleOwner) { editText.isEnabled = it == true }
        widget.maxLines?.bind(lifecycleOwner) { maxLines ->
            when (maxLines) {
                null -> editText.setSingleLine(false)
                1 -> editText.setSingleLine(true)
                else -> {
                    editText.setSingleLine(false)
                    editText.maxLines = maxLines
                }
            }
        }

        return ViewBundle(
            view = editText,
            size = size,
            margins = null
        )
    }
}
```

### iOS code
`mpp-library/src/iosMain/kotlin/org/example/mpp/PhoneInputViewFactory.kt`:
```kotlin
actual class PhoneInputViewFactory : ViewFactory<InputWidget<out WidgetSize>> {
    override fun <WS : WidgetSize> build(
        widget: InputWidget<out WidgetSize>,
        size: WS,
        viewFactoryContext: ViewFactoryContext
    ): ViewBundle<WS> {

        val textField = UITextField(frame = CGRectZero.readValue()).apply {
            translatesAutoresizingMaskIntoConstraints = false
            applyInputTypeIfNeeded(widget.inputType)

            clipsToBounds = true
        }

        val mask = widget.inputType?.mask
        if (mask != null) {
            val delegate = DefaultFormatterUITextFieldDelegate(
                inputFormatter = DefaultTextFormatter(
                    textPattern = mask.toIosPattern(),
                    patternSymbol = '#'
                )
            )
            textField.delegate = delegate
            setAssociatedObject(textField, delegate)
        }

        textField.setEventHandler(UIControlEventEditingChanged) {
            val currentValue = widget.field.data.value
            val newValue = textField.text

            if (currentValue != newValue) {
                widget.field.data.value = newValue.orEmpty()
            }
        }

        widget.enabled?.bind { textField.enabled = it }
        widget.label.bind { textField.placeholder = it.localized() }
        widget.field.data.bind { textField.text = it }

        return ViewBundle(
            view = textField,
            size = size,
            margins = null
        )
    }
}
```

### Apply to app
`mpp-library/src/commonMain/kotlin/org/example/mpp/App.kt`:
```kotlin
class App : BaseApplication() {
    override fun setup(): ScreenDesc<Args.Empty> {
        val theme = Theme() {
            ...

            factory[InputPhoneScreen.Ids.Phone] = PhoneInputViewFactory()
        }

        ...
    }

    ...
}
```

## Своя фабрика InputWidget с использованием нативных библиотек
Duration: 30

### Common code
`mpp-library/src/commonMain/kotlin/org/example/mpp/CodeInputViewFactory.kt`:
```kotlin
expect class CodeInputViewFactory() : ViewFactory<InputWidget<out WidgetSize>>
```

### Android code
`buildSrc/src/main/kotlin/Deps.kt`:
```kotlin
object Deps {
    ...

    object Libs {
        object Android {
            ...

            val otpView = AndroidLibrary(
                name = "com.github.GoodieBag:Pinview:v1.4"
            )
        }
    }

    ...
}
```

`build.gradle.kts`:
```kotlin
...
allprojects {
    repositories {
        ...

        maven { url = uri("https://jitpack.io") }
    }
    ...
}
...
```

`mpp-library/build.gradle.kts`:
```kotlin
...
dependencies {
    ...

    androidLibrary(Deps.Libs.Android.otpView)
}
...
```

`mpp-library/src/androidMain/kotlin/org/example/mpp/CodeInputViewFactory.kt`:
```kotlin
actual class CodeInputViewFactory actual constructor() : ViewFactory<InputWidget<out WidgetSize>> {
    override fun <WS : WidgetSize> build(
        widget: InputWidget<out WidgetSize>,
        size: WS,
        viewFactoryContext: ViewFactoryContext
    ): ViewBundle<WS> {
        val context = viewFactoryContext.androidContext
        val lifecycleOwner = viewFactoryContext.lifecycleOwner

        val editText = Pinview(context).apply {
            id = widget.id.androidId

            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )

            setOnFocusChangeListener { _, hasFocus ->
                if (!hasFocus) widget.field.validate()
            }
            setPinViewEventListener { pinview, fromUser ->
                widget.field.data.value = pinview.value
                widget.field.validate()
            }
        }

        widget.field.data.bind(lifecycleOwner) { data ->
            if (editText.value == data) return@bind

            editText.value = data
        }

        widget.enabled?.bind(lifecycleOwner) { editText.isEnabled = it == true }

        return ViewBundle(
            view = editText,
            size = size,
            margins = null
        )
    }
}
```

### iOS code
`buildSrc/build.gradle.kts`:
```kotlin
...
dependencies {
    implementation("dev.icerock:mobile-multiplatform:0.5.0")
    
    ...
}
...
```

`ios-app/Podfile`:
```ruby
...
target 'ios-app' do
  ...

  pod 'SVPinView', '1.0.7'
end
...
```
И требуется удалить автоустановку `mpp-library`: `cd .. && ./gradlew :mpp-library:syncMultiPlatformLibraryDebugFrameworkIosX64`.

`mpp-library/build.gradle.kts`:
```kotlin
...
cocoaPods {
    podsProject = file("../ios-app/Pods/Pods.xcodeproj")

    pod("SVPinView")
}
```

`mpp-library/src/iosMain/kotlin/org/example/mpp/CodeInputViewFactory.kt`:
```kotlin
actual class CodeInputViewFactory actual constructor() : ViewFactory<InputWidget<out WidgetSize>> {
    override fun <WS : WidgetSize> build(
        widget: InputWidget<out WidgetSize>,
        size: WS,
        viewFactoryContext: ViewFactoryContext
    ): ViewBundle<WS> {

        val textField = SVPinView(frame = CGRectZero.readValue()).apply {
            translatesAutoresizingMaskIntoConstraints = false

            setPlaceholder("****")
            
            heightAnchor.constraintEqualToConstant(80.0).active = true
        }

//        textField.setEventHandler(UIControlEventEditingChanged) {
//            val currentValue = widget.field.data.value
//            val newValue = textField.text
//
//            if (currentValue != newValue) {
//                widget.field.data.value = newValue.orEmpty()
//            }
//        }

//        widget.field.data.bind { textField.text = it }

        return ViewBundle(
            view = textField,
            size = size,
            margins = null
        )
    }
}
```

### sample code
`mpp-library/src/commonMain/kotlin/org/example/mpp/App.kt`:
```kotlin
class App : BaseApplication() {
    override fun setup(): ScreenDesc<Args.Empty> {
        val theme = Theme() {
            ...

            factory[InputCodeScreen.Ids.Code] = CodeInputViewFactory()
        }

        ...
    }

    ...
}
```
