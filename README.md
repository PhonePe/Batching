# Batching
A iOS batching library for analytics events.


## Installation

### CocoaPods

Add the following line to your Podfile:

```ruby
pod 'Batching'
```

## Usage

The Batching library uses core data (sqlite) to store events. Each event should be NSCoding compliant. 

To initialise the `PPBatchManager`:

```swift 
let batchManager = PPBatchManager(sizeStrategy: PPSizeBatchingStrategy(), timeStrategy: PPTimeBatchingStrategy(), dbName: "EventsDB")
```

You may customise the time and size strategies to suit your needs. 


To add an event to the DB:

```swift
 batchManager.addToBatch(event, timestamp: Date().timeIntervalSince1970)
```

`PPBatchManager` flushes the events back to you using a delegate callback. 


```swift
public func batchManagerShouldIngestBatch(_ manager: PPBatchManager, batch: [Any], completion: @escaping (Bool, Error?) -> Void) {
	//Here you may de-serialize your events and then feed it to an analytics service of your choice 
}

```


To force flush the events use:

```swift
batchManager.flush(true)
```


