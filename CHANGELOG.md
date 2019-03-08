## [0.0.1] - 2019/1/8

* Initial release.

## [0.0.2] - 2019/1/8

* Update readme.

## [0.0.3] - 2019/1/8

* Add basic documents to public interface.

## [0.0.4] - 2019/1/9

* Add `Store#get` as a shorthand of `Store#projectWith`

## [0.0.5] - 2019/1/9

* Rename `EventStore` to `Store`

## [0.0.6] - 2019/1/9

* Hide `Store#replaceEvents` from user

## [0.0.7] - 2019/1/9

* Add basic Flutter integration.

## [0.0.8] - 2019/1/10

* Update interface to match Redux better.
* Add ShakeBack enhancer.
* Add StoreBuilder interface.

## [0.0.9]

* Rename `build` in StoreBuilder's params to `builder`
* Eliminate rebuilds caused by StoreBuilder

## [0.0.10]

* Add description
* Rename `ShakeBack` API

## [0.0.11]

* Add example
* Update description

## [0.0.12]

* Rename `StoreWidget` interface
* Remove `Projectable` from signature of `Projector`
* Remove `EventStack`, using chronological `List` instead

## [0.1.0]

* Separate `Reducer` and `Initializer`
* Rename `InnerStore` to `StoreForEnhancer` 
* Expose more methods in `StoreForEnhancer` 

## [0.1.1]

* Remove `withShakeBack`
* Fix StackOverflow when get `Store#cursor`
* Remove unnecessary dependencies.

## [0.3.0]

* Update interface
* Add UseCase

## [0.3.2]

* Add ObservableStateLifecycle integration

## [0.4.0]

* Update observeStore interface

## [0.4.1]

* Use `active_observers`

## [0.5.0]

* Update file structure.