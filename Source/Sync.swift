import CoreData
import NSEntityDescription_SYNCPrimaryKey
import DATAFilter
import NSManagedObject_HYPPropertyMapper
import DATAStack

@objc public class Sync: NSOperation {
    var downloadFinished = false
    var downloadExecuting = false
    var downloadCancelled = false

    public override var finished: Bool {
        return self.downloadFinished
    }

    public override var executing: Bool {
        return self.downloadExecuting
    }

    public override var cancelled: Bool {
        return self.downloadCancelled
    }

    public override var asynchronous: Bool {
        return true
    }

    var changes: [[String : AnyObject]]
    var entityName: String
    var predicate: NSPredicate?
    var filterOperations = DATAFilter.Operation.All
    var parent: NSManagedObject?
    var context: NSManagedObjectContext?
    unowned var dataStack: DATAStack

    public init(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, context: NSManagedObjectContext?, dataStack: DATAStack, operations: DATAFilter.Operation = .All) {
        self.changes = changes
        self.entityName = entityName
        self.predicate = predicate
        self.parent = parent
        self.context = context
        self.dataStack = dataStack
        self.filterOperations = operations
    }

    public init(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, operations: DATAFilter.Operation = .All) {
        self.changes = changes
        self.entityName = entityName
        self.predicate = predicate
        self.dataStack = dataStack
        self.filterOperations = operations
    }

    public override func start() {
        func updateExecuting(isExecuting: Bool) {
            self.willChangeValueForKey("isExecuting")
            self.downloadExecuting = isExecuting
            self.didChangeValueForKey("isExecuting")
        }

        func updateFinished(isFinished: Bool) {
            self.willChangeValueForKey("isFinished")
            self.downloadFinished = isFinished
            self.didChangeValueForKey("isFinished")
        }

        if self.cancelled {
            updateExecuting(false)
            updateFinished(true)
        } else {
            updateExecuting(true)
            if let context = self.context {
                context.performBlock {
                    self.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: self.parent, parentRelationship: nil, inContext: context, dataStack: self.dataStack, operations: self.filterOperations) { error in
                        updateExecuting(false)
                        updateFinished(true)
                    }
                }
            } else {
                dataStack.performInNewBackgroundContext { backgroundContext in
                    self.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: self.parent, parentRelationship: nil, inContext: backgroundContext, dataStack: self.dataStack, operations: self.filterOperations) { error in
                        updateExecuting(false)
                        updateFinished(true)
                    }
                }
            }
        }
    }

    public override func cancel() {
        func updateCancelled(isCancelled: Bool) {
            self.willChangeValueForKey("isCancelled")
            self.downloadCancelled = isCancelled
            self.didChangeValueForKey("isCancelled")
        }

        updateCancelled(true)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: .All, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter dataStack: The DATAStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, dataStack: DATAStack, operations: DATAFilter.Operation, completion: ((error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: nil, dataStack: dataStack, operations: operations, completion: completion)
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, dataStack: dataStack, operations: .All, completion: completion)
        }
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter dataStack: The DATAStack instance.
     - parameter operations: The type of operations to be applied to the data, Insert, Update, Delete or any possible combination.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, dataStack: DATAStack, operations: DATAFilter.Operation, completion: ((error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: nil, parentRelationship: nil, inContext: backgroundContext, dataStack: dataStack, operations: operations, completion: completion)
        }
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
     an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
     you to send the parent album to do the proper mapping.
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, parent: NSManagedObject, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        dataStack.performInNewBackgroundContext { backgroundContext in
            let safeParent = parent.sync_copyInContext(backgroundContext)
            guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: backgroundContext) else { fatalError("Couldn't find entity named: \(entityName)") }
            let relationships = entity.relationshipsWithDestinationEntity(parent.entity)
            var predicate: NSPredicate? = nil

            if let firstRelationship = relationships.first {
                predicate = NSPredicate(format: "%K = %@", firstRelationship.name, safeParent)
            }

            self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: safeParent, parentRelationship: nil, inContext: backgroundContext, dataStack: dataStack, operations: .All, completion: completion)
        }
    }

    /**
     Syncs the entity using the received array of dictionaries, maps one-to-many, many-to-many and one-to-one relationships.
     It also syncs relationships where only the id is present, for example if your model is: Company -> Employee,
     and your employee has a company_id, it will try to sync using that ID instead of requiring you to provide the
     entire company object inside the employees dictionary.
     - parameter changes: The array of dictionaries used in the sync process.
     - parameter entityName: The name of the entity to be synced.
     - parameter predicate: The predicate used to filter out changes, if you want to exclude some local items to be taken in
     account in the Sync process, you just need to provide this predicate.
     - parameter parent: The parent of the synced items, useful if you are syncing the childs of an object, for example
     an Album has many photos, if this photos don't incldue the album's JSON object, syncing the photos JSON requires
     - parameter context: The context where the items will be created, in general this should be a background context.
     - parameter dataStack: The DATAStack instance.
     - parameter completion: The completion block, it returns an error if something in the Sync process goes wrong.
     */
    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, inContext context: NSManagedObjectContext, dataStack: DATAStack, completion: ((error: NSError?) -> Void)?) {
        self.changes(changes, inEntityNamed: entityName, predicate: predicate, parent: parent, parentRelationship: nil, inContext: context, dataStack: dataStack, operations: .All, completion: completion)
    }

    public class func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, dataStack: DATAStack, operations: DATAFilter.Operation, completion: ((error: NSError?) -> Void)?) {
        guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else { abort() }

        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        let shouldLookForParent = parent == nil && predicate == nil

        var finalPredicate = predicate
        if let parentEntity = entity.sync_parentEntity() where shouldLookForParent {
            finalPredicate = NSPredicate(format: "%K = nil", parentEntity.name)
        }

        if localPrimaryKey.isEmpty {
            fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using hyper.isPrimaryKey")
        }

        if remotePrimaryKey.isEmpty {
            fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
        }

        DATAFilter.changes(changes as [[String: AnyObject]], inEntityNamed: entityName, predicate: finalPredicate, operations: operations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { JSON in

            let created = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
            created.sync_fillWithDictionary(JSON, parent: parent, parentRelationship: parentRelationship, dataStack: dataStack, operations: operations)
        }) { JSON, updatedObject in
            updatedObject.sync_fillWithDictionary(JSON, parent: parent, parentRelationship: parentRelationship, dataStack: dataStack, operations: operations)
        }

        var syncError: NSError?
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                syncError = error
            } catch {
                fatalError("Fatal error")
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            completion?(error: syncError)
        }
    }

    func changes(changes: [[String : AnyObject]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, dataStack: DATAStack, operations: DATAFilter.Operation, completion: ((error: NSError?) -> Void)?) {
        guard let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) else { abort() }

        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        let shouldLookForParent = parent == nil && predicate == nil

        var finalPredicate = predicate
        if let parentEntity = entity.sync_parentEntity() where shouldLookForParent {
            finalPredicate = NSPredicate(format: "%K = nil", parentEntity.name)
        }

        if localPrimaryKey.isEmpty {
            fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using hyper.isPrimaryKey")
        }

        if remotePrimaryKey.isEmpty {
            fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using hyper.remoteKey to map to the right value")
        }

        DATAFilter.changes(changes as [[String : AnyObject]], inEntityNamed: entityName, predicate: finalPredicate, operations: operations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { JSON in
            guard self.cancelled == false else { return }

            let created = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context)
            created.sync_fillWithDictionary(JSON, parent: parent, parentRelationship: parentRelationship, dataStack: dataStack, operations: operations)
        }) { JSON, updatedObject in
            guard self.cancelled == false else { return }
            updatedObject.sync_fillWithDictionary(JSON, parent: parent, parentRelationship: parentRelationship, dataStack: dataStack, operations: operations)
        }

        var syncError: NSError?
        if context.hasChanges {
            if self.cancelled {
                context.reset()
            } else {
                do {
                    try context.save()
                } catch let error as NSError {
                    syncError = error
                } catch {
                    fatalError("Fatal error")
                }
            }
        }
        
        completion?(error: syncError)
    }
}
