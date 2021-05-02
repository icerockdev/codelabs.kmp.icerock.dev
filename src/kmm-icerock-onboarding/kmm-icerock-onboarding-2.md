summary: IceRock KMM onboarding #2
id: kmm-icerock-onboarding-2-ru 
categories: lang-ru,kmm-icerock-onboarding,moko 
status: published 
authors: Andrey Kovalev, Aleksey Lobynya, Aleksey Mikhailov 
tags: onboarding,kmm,ios,android,moko feedback
link: https://github.com/icerockdev/kmp-codelabs/issues

# IceRock KMM onboarding #2

## Построение навигации в iOS приложении

Duration: 20

Прежде чем идти дальше немного остановимся на том, как построена навигация в iOS приложение и какие
подходы при работе с ней мы используем.

В основе навигации лежат координаторы. Каждый координатор покрывает логически связанный блок
функционала, который чаще всего состоит из нескольких экранов. При этом между собой они независимы и
отвечают только за цепочку переходов только внутри себя. Также имеют возможность получать настройку
действия, которое должно быть выполнено после завершения блока ответственности координатора.

Например.

Предположим, что у нас есть приложение, в котором имеется авторизация, просмотр списка новостей, с
возможностью перехода к детальному виду каждой новости, а со списка новостей можно попасть в раздел
настроек для конфигурации отображения новостей. Это разобьётся на 4 координатора:

1. AppCoordinator
    1. Стартовый координатор. Всегда является первой входной точкой, определяет, куда должен
       выполниться дальнейший переход при запуске приложения
    2. Если юзер не авторизован - запустит координатор авторизации и в качестве completionHandler-а
       укажет ему переход на новости в случае успешной авторизации
    3. Если юзер уже авторизован - запустит координатор просмотра новостей
2. AuthCoordinator
    4. Запустит процесс авторизации
    5. Будет совершать переходы по всем требуемым шагам - например ввод логина/пароля, смс-кода,
       установки никнейма и т.п.
    6. По итогу успешной авторизации вызовет переданный ему на вход completionHandler.
3. NewsCoordinator
    7. Отвечает за показ списка новостей
    8. Реализовывает переход в детали конкретной новости внутри этого же координатора
    9. При переходе в настройки создаёт координатор настроек, с качестве completionHandler-а может
       передать ему логику обновления своего списка новостей. Если в настройках изменились параметры
        - обновляет список
4. SettingsCoordinator
    10. Отвечает за работу с экраном настроек
    11. При завершении работы и применении настроек вызывает completion, чтобы новости обновились

Именно координаторы реализуют интерфейс EventListener-ов вьюмоделей, о которых будет чуть ниже. Так
как вызов переходов завязан на бизнес-логику приложения, то инициатором этих переходов являются
именно вьюмодели. Поэтому координаторы выполняют связующую роль между тем, что происходит в логике
приложений и тем, как это должно отражаться пользователю.

Чтобы работать с координаторами было проще, используется базовый класс, от которого наследуются
остальные. Добавим его к нашему проекту.

Создадим в ios-проекте папку src/Coordinators и в ней файлик BaseCoordinator. Для начала докинем
туда пару протоколов:

```swift

protocol ChildCoordinable {

    var childCoordinators: [Coordinator] { get set }

    func addDependency(_ coordinator: Coordinator)

    func removeDependency(_ coordinator: Coordinator?)

}
```

ChildCoordinable - необходим для корректной работы с зависимостями от дочерних координаторов.
Необходимо не забывать добавлять зависимости на новый координаторы, очищать зависимость на
конкретный координатор и запоминать список тех координаторов, которые являются дочерними к текущему.

```swift
protocol Coordinator: class {

    var completionHandler: (() -> Void)? { get set }

    

    func start()

}
```

Coordinator - сам протокол координатора. По сути он должен иметь ровно две вещи - completionHandler,
который вызовется при завершении его логической зоны ответственности. И функцию start. При её вызове
он начинает запускать свой флоу таким образом, каким считает нужным.

И далее сам класс базового координатора, который реализует оба этих протокола:

```swift

class BaseCoordinator: NSObject, Coordinator, ChildCoordinable, UINavigationControllerDelegate {

    var childCoordinators: [Coordinator] = []

    var completionHandler: (() -> Void)?

    

    let window: UIWindow

    

    weak var navigationController: UINavigationController?

    

    init(window: UIWindow) {

        self.window = window

    }

    

    func start() {

        

    }

    

    func addDependency(_ coordinator: Coordinator) {

        for element in childCoordinators where element === coordinator {

            return

        }

        childCoordinators.append(coordinator)

    }

    

    func removeDependency(_ coordinator: Coordinator?) {

        guard

            childCoordinators.isEmpty == false,

            let coordinator = coordinator

        else { return }

        

        for (index, element) in childCoordinators.enumerated() where element === coordinator {

            

            childCoordinators.remove(at: index)

            break

            

        }

    }

    

    func currentViewController() -> UIViewController? {

        return self.navigationController?.topViewController?.presentedViewController ?? self.navigationController?.topViewController ?? self.navigationController

    }

    

    func popBack() {

        self.navigationController?.popViewController(animated: true)

    }

}
```

Для инициализации необходим только window. Также можно указать NavigationController с предыдущего
координатора, для сохранения общей навигации.

Добавление и удаление зависимостей нужны для корректной очистки связей и памяти при построении
цепочек координаторов.

Также есть вспомогательные методы, которые позволяют получить текущий контроллер -
currentViewController и совершить переход назад - popBack.

От проекта к проекту базовый координатор может изменяться, обеспечивая дополнительные нужды проекта.

Теперь, когда у нас есть базовый координатор, создадим на его основе стартовый координатор
приложения. Создаём рядом с AppDelegate файл для него, называем AppCoordinator:

```swift

import Foundation

import UIKit

class AppCoordinator: BaseCoordinator {

    // MARK:** - Overrides**

    override func start() {

        let vc = UIViewController()

        vc.view.backgroundColor = UIColor.green

        self.window.rootViewController = vc

    }

}
```

Пусть он пока будет совсем простой, создающий контроллер зелёного цвета и делает его главным экраном
window.

Теперь нам надо познакомить AddDelegate с его координатором. Идём в AppDelegate.swift

Добавим ему ссылку на координатор приложения:

private (set) var coordinator: AppCoordinator!

А в didFinishLaunchingWithOptions после создания SharedFactory добавим создание координатора и вызов
старта:

```swift

self.coordinator = AppCoordinator(

            window: self.window!

        )

self.coordinator.start()
```

Готово. Собираем, запускаем и видим наш зелёный контроллер:

Теперь дальнейшая логика переходов зависит от текущего контроллера и действий юзера на нём. Но
зелёным прямоугольником мир не спасёшь и юзера не авторизуешь. Поэтому пора переходить к созданию
нашей первой фичи.
