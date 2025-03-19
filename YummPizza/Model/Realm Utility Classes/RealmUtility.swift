import RealmSwift

extension Realm
{
   public class var main : Realm {
      return try! Realm()
   }
   
   @objc public func writeWithTransactionIfNeeded(_ block: () -> Void)
   {
      if isInWriteTransaction {
         block()
      }
      else {
         try? write(block)
      }
   }
   
   
   // MARK: Cascade deletion
   
   public func cascadeDelete(_ object: Object)
   {
      guard !object.isInvalidated else { return }
      
      var deleteArray : [Object] = []
      object.fillObjectsToCascadeDelete(deleteArray: &deleteArray)
      delete(deleteArray)
   }
   
   public func cascadeDelete<S: Sequence>(_ objects: S) where S.Iterator.Element: Object
   {
      var deleteArray : [Object] = []
      for object in objects {
         object.fillObjectsToCascadeDelete(deleteArray: &deleteArray)
      }
      delete(deleteArray)
   }
}


protocol RealmCascadeDeletion : AnyObject
{
   func fillObjectsToCascadeDelete(deleteArray : inout [Object])
}

public protocol RealmStandaloneDeepCopying : AnyObject
{
   func standaloneDeepCopy() -> RealmStandaloneDeepCopying
   func standaloneDeepCopy(copiedObjects : inout [(original : Object, copied : Object)]) -> RealmStandaloneDeepCopying?
}


extension Object : RealmCascadeDeletion, RealmStandaloneDeepCopying
{
   public func modifyWithTransactionIfNeeded(_ block: () -> Void)
   {
      guard !isInvalidated else { return }
      
      if let selfRealm = realm {
         selfRealm.writeWithTransactionIfNeeded(block)
      }
      else {
         block()
      }
   }
   
   
   // MARK: Cascade deletion
   
   @objc public func propertiesToCascadeDelete() -> [String] { return [] }
   
   func fillObjectsToCascadeDelete(deleteArray : inout [Object])
   {
      guard !isInvalidated else { return }
      if deleteArray.index(where: { $0.isEqual(self) }) != nil { return }
      
      if self.realm != nil {
         deleteArray.append(self)
      }
      
      let propertiesToDelete = propertiesToCascadeDelete()
      for propertyName in propertiesToDelete
      {
         guard let object = self[propertyName] as? RealmCascadeDeletion else { continue }
         object.fillObjectsToCascadeDelete(deleteArray: &deleteArray)
      }
   }
   
   // MARK: Standalone deep copy
   
   public func standaloneDeepCopy() -> RealmStandaloneDeepCopying
   {
      var copiedObjects : [(original : Object, copied : Object)] = []
      return standaloneDeepCopy(copiedObjects: &copiedObjects) ?? self
   }
   
   public func standaloneDeepCopy(copiedObjects : inout [(original : Object, copied : Object)]) -> RealmStandaloneDeepCopying?
   {
      guard !isInvalidated else { return nil }
      
      if let alreadyCopied = copiedObjects.first(where: { $0.original.isEqual(self) }) {
         return alreadyCopied.copied
      }
      
      let copied = type(of: self).init()
      copiedObjects.append((self, copied))
      
      for property in objectSchema.properties
      {
         if let object = self[property.name] as? RealmStandaloneDeepCopying {
            copied[property.name] = object.standaloneDeepCopy(copiedObjects: &copiedObjects)
         }
         else {
            copied[property.name] = self[property.name]
         }

      }
      
      return copied
   }
}

extension Results
{
   public func toArray() -> Array<T> {
      return Array<T>(self)
   }
}

extension List : RealmStandaloneDeepCopying, RealmCascadeDeletion
{
   public func modifyWithTransactionIfNeeded(_ block: () -> Void)
   {
      guard !isInvalidated else { return }
      
      if let selfRealm = realm {
         selfRealm.writeWithTransactionIfNeeded(block)
      }
      else {
         block()
      }
   }
   
   public func toArray() -> Array<T> {
      return Array<T>.init(self)
   }
   
   // MARK: Cascade deletion
   
   func fillObjectsToCascadeDelete(deleteArray : inout [Object])
   {
      guard !isInvalidated else { return }
      for object in self {
         object.fillObjectsToCascadeDelete(deleteArray: &deleteArray)
      }
   }
   
   // MARK: Standalone deep copy
   
   public func standaloneDeepCopy() -> RealmStandaloneDeepCopying
   {
      var copiedObjects : [(original : Object, copied : Object)] = []
      return standaloneDeepCopy(copiedObjects: &copiedObjects) ?? self
   }
   
   public func standaloneDeepCopy(copiedObjects : inout [(original : Object, copied : Object)]) -> RealmStandaloneDeepCopying?
   {
      guard !isInvalidated else { return nil }
      
      let copiedList = List<T>.init()
      for object in self
      {
         if let copiedObject = object.standaloneDeepCopy(copiedObjects: &copiedObjects) as? T {
            copiedList.append(copiedObject)
         }
      }
      
      return copiedList
   }
}

extension LinkingObjects : RealmCascadeDeletion
{
   // MARK: Cascade deletion
   
   func fillObjectsToCascadeDelete(deleteArray : inout [Object])
   {
      guard !isInvalidated else { return }
      for object in self {
         object.fillObjectsToCascadeDelete(deleteArray: &deleteArray)
      }
   }
}
