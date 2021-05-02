summary: Как вносить изменения в moko библиотеки самостоятельно
id: moko-contribution-ru
categories: lang-ru,moko
status: published
Feedback Link: https://github.com/icerockdev/kmp-codelabs/issues
Analytics Account: UA-81805223-5
Author: Aleksey Mikhailov <am@icerock.dev>

# MOKO contribution guide
## Вводная
Duration: 2

В этом уроке разобрано как можно использовать в своих проектах moko библиотеки и вносить в них изменения.

Для работы потребуется:
- Android Studio 3.4.0+;
- Xcode 10.3+;
- Xcode Command Line Tools (`xcode-select --install`);

## Готовим свой проект
Duration: 5

Для начала склонируем какой-либо проект с moko библиотеками. Например - [moko-template](https://github.com/icerockdev/moko-template). Его не требуется донастраивать, можно просто склонировать и сразу запускать.

`git clone https://github.com/icerockdev/moko-template.git`

Далее убедимся что проект корректно компилируется. 
- Android - открываем Android Studio и после завершения gradle sync запускаем приложение (Run);
- iOS - вызываем `pod install` в дирректории `ios-app`, а после завершения открываем `ios-app.xcworkspace` и жмем Run.

После этого определяем какую библиотеку будем модифицировать. Для примера выберем `moko-mvvm` и в качестве цели модификации выберем "добавить в LiveData вывод в лог информацию о добавлении нового observable и о удалении". Так как в приложении уже есть использование вьюмоделей и лайвдат - мы сможем легко проверить реализацию.

## Вносим изменения в библиотеку
Duration: 10

Для внесения изменений в библиотеку потребуется:
1. Создать fork [moko-mvvm](https://github.com/icerockdev/moko-mvvm);
2. Склонировать себе данный fork;
3. Открыть склонированный проект.

После открытия проекта через `Android Studio` внесем нужные изменения в библиотеку. 
Для этого в модуле `mvvm` нужно будет внести изменения для android и iOS реализаций LiveData:

### Android
Находим файл `src/androidMain/kotlin/dev/icerock/moko/mvvm/livedata/LiveData.kt`.
Обновляем код:
```kotlin
    actual fun addObserver(observer: (T) -> Unit) {
        println("livedata $this addObserver $observer")

        val archObserver = Observer<T> { value ->
            if (value is T) observer(value)
        }
        observers[observer] = archObserver

        archLiveData.observeForever(archObserver)
    }

    actual fun removeObserver(observer: (T) -> Unit) {
        println("livedata $this removeObserver $observer")

        val archObserver = observers.remove(observer) ?: return
        archLiveData.removeObserver(archObserver)
    }
```

### iOS
Находим файл `src/iosMain/kotlin/dev/icerock/moko/mvvm/livedata/LiveData.kt`.
Обновляем код:
```kotlin
    actual fun addObserver(observer: (T) -> Unit) {
        println("livedata $this addObserver $observer")

        observer(value)
        observers.add(observer)
    }

    actual fun removeObserver(observer: (T) -> Unit) {
        println("livedata $this removeObserver $observer")

        observers.remove(observer)
    }
```

### Публикация изменений для использования в других проектах
Теперь, когда изменения в библиотеку внесены, нужно опубликовать эти изменения. Для проверки корректности мы можем опубликовать изменения локально, в `mavenLocal`. Для этого нужно вызвать gradle task `:mvvm:publishToMavenLocal`. Подсказка о том как развернуть локально moko библиотеку указана в [разделе Set Up Locally в README](https://github.com/icerockdev/moko-mvvm#set-up-locally).

После успешного завершения задачи мы можем использовать опубликованную версию библиотеки в других проектах на данном локальном хосте.

## Подключаем измененную библиотеку к проекту
Duration: 5

Для подключения библиотеки из локального maven нужно внести изменения в конфигурацию проекта:
root build.gradle.kts
```kotlin
allprojects {
    repositories {
        mavenLocal() // <-- добавляем эту строку, она означает что сначала нужно искать зависимости в локальном репозитории
        
        google()
        jcenter()

        maven { url = uri("https://kotlin.bintray.com/kotlin") }
        maven { url = uri("https://kotlin.bintray.com/kotlinx") }
        maven { url = uri("https://dl.bintray.com/icerockdev/moko") }
        maven { url = uri("https://kotlin.bintray.com/ktor") }
        maven { url = uri("https://dl.bintray.com/aakira/maven") }
    }

    // workaround for https://youtrack.jetbrains.com/issue/KT-27170
    configurations.create("compileClasspath")
}
```

После добавления `mavenLocal` репозитория можно выполнять компиляцию проекта и мы увидим что теперь в логи пишутся сообщения, добавленные нами в `moko-mvvm`.

## Публикация в общий доступ
Duration: 5

- Так как публикация выполнена локально, то изменения будут доступны только при сборка на данном хосте;
- После того как изменения будут проверены локально их нужно закоммитить в свой fork библиотеки и создать pull request в оригинальный moko-репозиторий;
- После принятия реквеста нужно дождаться выхода новой версии moko библиотеки и применить эту версию в своем проекте.