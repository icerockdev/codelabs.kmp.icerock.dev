summary: MOKO Widgets #8 - создание виджета
id: moko-widgets-8
categories: moko
environments: kotlin-mobile-mpp
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Mikhailov <am@icerock.dev>

# MOKO Widgets #8 - create new widget
## Вводная
Duration: 5

Урок является продолжением [MOKO Widgets #7 - lists on widgets](https://codelabs.kmp.icerock.dev/codelabs/moko-widgets-7/). Для выполнения данного урока нужно иметь проект, полученный в результате выполнения предыдущего урока.

Результатом прошлого урока было приложение с навигацией, стилизацией экранов, различными действиями на экранах, кастомными фабриками, платформенным экраном и списком друзей.

На этом уроке мы реализуем новый виджет - слайдер (для выбора значения в заданном диапазоне).

## Создание класса виджета
Duration: 10

`mpp-library/build.gradle.kts`:
```kotlin
plugins {
    ...
    id("dev.icerock.mobile.multiplatform-widgets-generator")
}
```

`mpp-library/src/commonMain/kotlin/org/example/mpp/info/SliderWidget.kt`:
```kotlin
@WidgetDef(SliderViewFactory::class)
class SliderWidget<WS : WidgetSize>(
    override val size: WS,
    private val factory: ViewFactory<SliderWidget<out WidgetSize>>,
    override val id: Id,
    val minValue: Int,
    val maxValue: Int,
    val value: MutableLiveData<Int>
) : Widget<WS>(), RequireId<SliderWidget.Id> {
    override fun buildView(viewFactoryContext: ViewFactoryContext): ViewBundle<WS> {
        return factory.build(this, size, viewFactoryContext)
    }

    interface Id : Theme.Id<SliderWidget<out WidgetSize>>
    interface Category : Theme.Category<SliderWidget<out WidgetSize>>

    object DefaultCategory : Category
}
```

## Создание фабрики виджета
Duration: 10

`mpp-library/src/commonMain/kotlin/org/example/mpp/info/SliderViewFactory.kt`:
```kotlin
expect class SliderViewFactory() : ViewFactory<SliderWidget<out WidgetSize>>
```

`mpp-library/src/androidMain/kotlin/org/example/mpp/info/SliderViewFactory.kt`:
```kotlin
actual class SliderViewFactory : ViewFactory<SliderWidget<out WidgetSize>> {
    override fun <WS : WidgetSize> build(
        widget: SliderWidget<out WidgetSize>,
        size: WS,
        viewFactoryContext: ViewFactoryContext
    ): ViewBundle<WS> {
        val context = viewFactoryContext.androidContext
        val lifecycleOwner = viewFactoryContext.lifecycleOwner

        val slider = SeekBar(context).apply {
            max = widget.maxValue - widget.minValue
        }

        widget.value.bindNotNull(lifecycleOwner) { slider.progress = it - widget.minValue }

        slider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                val fixedProgress = progress + widget.minValue
                if (widget.value.value == fixedProgress) return

                widget.value.value = fixedProgress
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) {}

            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })

        return ViewBundle(
            view = slider,
            size = size,
            margins = null
        )
    }
}
```

`mpp-library/src/iosX64Main/kotlin/org/example/mpp/info/SliderViewFactory.kt`:
```kotlin
actual class SliderViewFactory : ViewFactory<SliderWidget<out WidgetSize>> {
    override fun <WS : WidgetSize> build(
        widget: SliderWidget<out WidgetSize>,
        size: WS,
        viewFactoryContext: ViewFactoryContext
    ): ViewBundle<WS> {
        val slider = UISlider(frame = CGRectZero.readValue()).apply {
            translatesAutoresizingMaskIntoConstraints = false

            minimumValue = widget.minValue.toFloat()
            maximumValue = widget.maxValue.toFloat()
        }

        widget.value.bind { slider.value = it.toFloat() }
        slider.setEventHandler(UIControlEventValueChanged) {
            val value = slider.value.toInt()
            slider.value = value.toFloat()
            
            if (widget.value.value == value) return@setEventHandler

            widget.value.value = value
        }

        return ViewBundle(
            view = slider,
            size = size,
            margins = null
        )
    }
}
```

## Тестирование
Duration: 10

`mpp-library/src/commonMain/kotlin/org/example/mpp/profile/ProfileScreen.kt`:
```kotlin
class ProfileScreen(
    ...
) : ... {
    ...

    override fun createContentWidget() = with(theme) {
        val sliderValue = MutableLiveData<Int>(initialValue = 0)

        constraint(size = WidgetSize.AsParent) {
            ...

            val slider = +slider(
                size = WidgetSize.WidthAsParentHeightWrapContent,
                id = Ids.Slider,
                minValue = -5,
                maxValue = 5,
                value = sliderValue
            )

            val valueText = +text(
                size = WidgetSize.WidthAsParentHeightWrapContent,
                text = sliderValue.map { it.toString().desc() as StringDesc }
            )

            constraints {
                ...

                slider bottomToTop editButton offset 16
                slider leftRightToLeftRight root

                valueText bottomToTop slider offset 16
                valueText leftRightToLeftRight root
            }
        }
    }

    object Ids {
        object Slider : SliderWidget.Id
    }
}
```

В результате получаем:

|android app|ios app|
|---|---|
|![android-app](assets/moko-widgets-8-android-slider.png)|![ios-app](assets/moko-widgets-8-ios-slider.png)|