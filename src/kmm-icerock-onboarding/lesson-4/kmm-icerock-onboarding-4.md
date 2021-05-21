id: kmm-icerock-onboarding-4-ru
categories: lang-ru,kmm-icerock-onboarding,moko
status: published
authors: ??
tags: onboarding,kmm,ios,android,moko
feedback link: https://github.com/icerockdev/kmp-codelabs/issues

# IceRock KMM onboarding #4 - реализация фичи списка

## Вводная

В этой кодлабе мы рассмотрим как реализовать фичи списка по принятому в IceRock стандарту, используя наши библиотеки [moko-units](https://github.com/icerockdev/moko-units) и [moko-mvvm](https://github.com/icerockdev/moko-mvvm)
Основнная особенность нашего подхода - на нативных платформах используются UITableView/UICollectionView и RecyclerView, тогда как вся логика по построению списка этих элементов и наполнению данными реализуется в common коде.


## Добавляем в проект новую пустую фичу

Duration: 25

### Создаем новый модуль в mpp-library

Для начала, по аналогии с [третьей кодлабой](https://codelabs.kmp.icerock.dev/codelabs/kmm-icerock-onboarding-3-ru/index.html) по пути `mpp-library/feature/` создаем директорию для нашего модуля следующей структуры:

```tree
.
|____build.gradle.kts
|____src
| |____commonMain
| | |____kotlin
| | | |____org
| | | | |____example
| | | | | |____library
| | | | | | |____feature
| | | | | | | |____listSample
| | | | | | | | |____di
| | | | | | | | | |____ListSampleFactory.kt
| | | | | | | | |____presentation
| | | | | | | | | |____ListSampleViewModel.kt
| |____androidMain
| | |____AndroidManifest.xml
```

Здесь:
- вложенные директории org/example/library/feature/listSimple должны соответствовать имени пакета ([//TODO: ссылка на "почему так?"]())
- в директории di будет распологаться весь код внешнего создания вьюмодели доступный внешним модулям, сейчас это фабрика вьюмодели
- в директории presentation будет именно ViewModel-логика, то есть сами классы вьюмоделей и возможно что-нибудь вспомогательное для них, доступное только в рамках модуля фичи

Cтартовое состояние файлов такое же как в начале третьей кодлабы, только заменены имена классов и пакетов:

ListSampleViewModel.kt:
```kotlin
package org.example.library.feature.listSample.presentation

import dev.icerock.moko.mvvm.dispatcher.EventsDispatcher
import dev.icerock.moko.mvvm.dispatcher.EventsDispatcherOwner
import dev.icerock.moko.mvvm.viewmodel.ViewModel

class ListSampleViewModel(
    override val eventsDispatcher: EventsDispatcher<EventsListener>,
) : ViewModel(), EventsDispatcherOwner<ListSampleViewModel.EventsListener> {
    interface EventsListener	//пока что пустой интерфейс
}
```

ListSampleFactory.kt;
```kotlin
package org.example.library.feature.listSample.di

import dev.icerock.moko.mvvm.dispatcher.EventsDispatcher
import org.example.library.feature.listSample.presentation.ListSampleViewModel

class ListSampleFactory {
    fun createListViewModel(
        eventsDispatcher: EventsDispatcher<ListSampleViewModel.EventsListener>
    ) = ListSampleViewModel(
        eventsDispatcher = eventsDispatcher
    )
}
```

AndroidManifest.xml:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest package="org.example.library.feature.listSample" />
```

Теперь нужно указать что наш модуль участвует в gradle-проекте. Добавляем его в `settings.gradle` в корне проекта:

```gradle
include(":mpp-library:feature:auth")
include(":mpp-library:feature:listSample") //добавляем наш новый модуль
```

Чтобы ссылаться на этот модуль, необходимо завести его в структуре зависимостей в файле ./buildSrc/src/main/kotlin/Deps.kt. Как и авторизацию, добавим его в список фичей:
```kotlin
            val listSample = MultiPlatformModule(
                name = ":mpp-library:feature:listSample",
                exported = true
            )
```
флаг exported указывает что при сборке этот модуль попадет в платформенный фреймворк и будет доступен со стороны iOS (//TODO: пояснить когда не надо указывать его)

Теперь можно сослаться на модуль фичи из основного в ./mpp-library/build.gradle.kts:
```kts
val mppModules = listOf(
    Deps.Modules.Feature.auth,
    Deps.Modules.Feature.listSample //Добавляем наш модуль
)
```

Осталось выполнить синхронизацию gradle, плагин для студии предлагает сделать после каждого изменения gradle-файлов:
![gradle-sync](assets/gradle-sync.png)

В итоге наш модуль доступен в основном коде mpp-library, как и для авторизации реализуем фабрику вьюмодели в ./mpp-library/SharedFactory.kt:
```kotlin
...
import org.example.library.feature.auth.di.AuthFactory
import org.example.library.feature.listSample.di.ListSampleFactory //можем добавить импорт самостоятельно, но IDE сама предложит это сделать при упоминании в коде классов из этого модуля

...

   // init factories here
    val authFactory: AuthFactory by lazy {
        AuthFactory()
    }

    // listSample factory setup
    val listSampleFactory: ListSampleFactory by lazy {
        ListSampleFactory()
    }

    init {
    ...
```

На этом базовый каркас заготовки фичи со стороны общего кода готов

### Создаем новый UIViewController на iOS, связываем  его с ViewModel

### Создаем новый фрагемент/активность(?) на Android, связываем  его с ViewModel

## Дополняем в фичу простой вариант списка юнитов

Duration: 15
### Пояснение про moko-units

### Добавляем базовый функционал в common-коде

###  Верстаем и привязываемся к данным на стороне iOS

###  Верстаем и привязываемся к данным на стороне Android

##  Расширяем возможности фичи, учитываем дополнительные состояния данных

Duration: 15