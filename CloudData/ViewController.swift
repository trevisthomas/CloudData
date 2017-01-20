//
//  ViewController.swift
//  CloudData
//
//  Created by Trevis Thomas on 1/12/17.
//  Copyright © 2017 Trevis Thomas. All rights reserved.
//

import UIKit
import CloudKit

/*
 TODO:
 
 Figure out how to update the user record.
 Figure out how to generate an enfocaId for new users
 Implement pagination - Done.  QueryOperation is your frind.
 */
 

class ViewController: UIViewController {
    
    var db: CKDatabase!
    var pairs : [WordPair] = []
    var tags: [Tag] = []
    var enfocaId : NSNumber!

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var wordTextField: UITextField!
    @IBOutlet weak var definitionTextField: UITextField!
    
    @IBOutlet weak var moreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = CKContainer.default().publicCloudDatabase
        
        loadUser { (id: Int?) in
            guard let id = id else {
                print("Not logged in")
                fatalError() //Not logged in
            }
            
            self.enfocaId = NSNumber(value: id)
            print("Loaded enfoca user: \(self.enfocaId)")
            self.reloadAll()
        }
    }
    
   
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refreshAction(_ sender: Any){
        reloadAll()
    }
    
    var selectedTags : [Tag] = []
    @IBAction func selectTagAction(_ sender: Any) {
        let tagIndex = pickerView.selectedRow(inComponent: 0)
        let tag = tags[tagIndex]
        selectedTags.append(tag)
    }
    
    @IBAction func filterAction(_ sender: Any) {
        loadCloudDataWordPairs(with: selectedTags)
        selectedTags = []
        
    }
    
    @IBAction func clearFilterAction(_ sender: Any) {
        selectedTags = []
    }
    
    @IBAction func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    var cursor : CKQueryCursor? {
        didSet{
            OperationQueue.main.addOperation({
                if self.cursor != nil {
                    self.moreButton.isEnabled = true
                } else {
                    self.moreButton.isEnabled = false
                }
            })
        }
    }
    
    @IBAction func moreButtonAction(_ sender: Any) {
        self.loadCloudDataWordPairs(referenceIds: nil, cursor: self.cursor, callback: { (cursor : CKQueryCursor) in
            self.cursor = cursor
        })
        self.cursor = nil
    }
    
    private func reloadAll() {
        //Trevis, with icloud i think that you can bundle these calls together
        loadCloudDataTags {
            self.loadCloudDataWordPairs()
        }
    }
    
    func loadUser(completion: @escaping (Int?)->()) {
        CKContainer.default().fetchUserRecordID { (recordId: CKRecordID?, error:Error?) in
            if error != nil {
                print("Error while loading user: \(error)")
                completion(nil)
                return
            }
            self.db.fetch(withRecordID: recordId!, completionHandler: { (record: CKRecord?, error: Error?) in
                guard let id = record?.value(forKey: "enfocaId") as? Int else {
                    self.createEnfocaId(callback: completion)
                    return
                }
                completion(id)
            })
        }
    }
    
    func createEnfocaId(callback: @escaping (Int?) -> ()){
        let settingsId = CKRecordID(recordName: "9ea8a03a-9867-4365-8ece-94380971bc13")
        
        
        self.db.fetch(withRecordID: settingsId, completionHandler: { (record: CKRecord?, error: Error?) in
            guard let id = record?.value(forKey: "Seed") as? Int, let record = record else {
                callback(nil)
                return
            }
            let enfocaId = id + 1
            record.setValue(enfocaId, forKey: "Seed")
            self.db.save(record, completionHandler: { (record:CKRecord?, error:Error?) in
                if let error = error {
                    print(error)
                    fatalError() //Handle error.  Here is where we'd end up if the error record was updated while you were updating it
                }
                self.updateUserRecord(enfocaId: enfocaId, callback: { (success: Bool) in
                    if success {
                        callback(enfocaId)
                    } else {
                        fatalError()//Failed to save the record to the user!
                    }
                })
                
            })
        })
    }
    
    
    //Returns true to callback if record update was successfull
    func updateUserRecord(enfocaId: Int, callback: @escaping(Bool)->()){
        CKContainer.default().fetchUserRecordID { (recordId: CKRecordID?, error:Error?) in
            if error != nil {
                print("Error while loading user: \(error)")
                callback(false)
                return
            }
            
            self.db.fetch(withRecordID: recordId!, completionHandler: { (record: CKRecord?, error: Error?) in
                guard let record = record else {
                    callback(false)
                    return
                }
                record.setValue(enfocaId, forKey: "enfocaId")
                self.db.save(record, completionHandler: { (record:CKRecord?, error:Error?) in
                    if let error = error {
                        print(error)
                        fatalError() //Failed to update.   What to do!?
                    }
                    callback(true)
                })
            })
            
            
        }
    }

    @IBAction func tagSelectedWord(_ sender: Any) {
        guard let ip = tableView.indexPathForSelectedRow else {
            print("nothing selected to tag")
            return
        }
        let wp = pairs[ip.row]
        let tagIndex = pickerView.selectedRow(inComponent: 0)
        let tag = tags[tagIndex]
        
        print("Tagging \(wp.word) with \(tag.name)")
        
        cloudKitTagWordPair(wordPair: wp, tag: tag)
    }
    
    
    @IBAction func addWordPairAction(_ sender: Any) {
        guard let word = wordTextField.text, isValid(word) else {
            return
        }
        
        guard let defintion = definitionTextField.text, isValid(defintion) else {
            return
        }
        
        let wpRecord : CKRecord = CKRecord(recordType: "SimpleWordPair")
        wpRecord.setValue(word, forKey: "Word")
        wpRecord.setValue(defintion, forKey: "Definition")
        wpRecord.setValue(enfocaId, forKey: "enfocaId")
        
        db.save(wpRecord) { (record: CKRecord?, error: Error?) in
            if error != nil {
                print("Error while saving: \(error)")
                return
            }
            print("Record saved successfully")
            OperationQueue.main.addOperation({ 
                self.wordTextField.text = nil
                self.definitionTextField.text = nil
                
                self.pairs.append(self.toWordPair(from: wpRecord))
                self.tableView.reloadData()
            })
        }
    }
    
    //This impl uses the local list of tags.
    private func findTagsWithReferences(tagReferences: [CKReference]) -> [Tag]{
        var list : [Tag] = []
        for ref in tagReferences {
            guard let t = findTag(recordId : ref.recordID) else {
                print("Warning, there is a word pair with a tag that is not loaded.  Assumption is that the local tag list is out of sync")
                continue
            }
            list.append(t)
        }
        
        return list
    }
    
    private func findTag(recordId: CKRecordID) -> Tag? {
        for tag in tags {
            if (tag.recordId == recordId) {
               return tag
            }
        }
        return nil
    }
    
    func loadCloudDataWordPairs(){
        self.cursor = nil
        self.loadCloudDataWordPairs(referenceIds: nil, cursor: nil, callback: { (cursor : CKQueryCursor) in
            self.cursor = cursor
        })
    }
    
    
    func loadCloudDataWordPairs(with tags : [Tag]){
        //CKRecordID's should be querried with CKReferences.
        let tagRefs : [CKReference] = tags.map { (tag: Tag) -> CKReference in
            return CKReference(recordID: tag.recordId, action: .none)
        }

        let predicate : NSPredicate = NSPredicate(format: "enfocaId == %@ AND TagRef in %@", enfocaId, tagRefs)
        let query: CKQuery = CKQuery(recordType: "SimpleTagAss", predicate: predicate)
        db.perform(query, inZoneWith: nil) { (records : [CKRecord]?, error : Error?) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let records = records, records.count > 0 else {
                print("Records is nil")
                return
            }
            
            var referenceIds : [CKReference] = []
            for record in records {
                let wordRef = record.value(forKey: "WordRef") as! CKReference
                referenceIds.append(wordRef)
            }
            
            self.cursor = nil
            self.loadCloudDataWordPairs(referenceIds: referenceIds, cursor: nil, callback: { (cursor : CKQueryCursor) in
                self.cursor = cursor
            })
        }
    }
    

    func loadCloudDataWordPairs(referenceIds : [CKReference]?, cursor : CKQueryCursor? = nil, callback: @escaping (CKQueryCursor)->()){
        
        //        https://developer.apple.com/reference/cloudkit/ckquery#//apple_ref/occ/cl/CKQuery
        //        http://stackoverflow.com/questions/32900235/how-to-query-cloudkit-for-recordid-in-ckrecordid
        
        
        let operation : CKQueryOperation
        
        if let cursor = cursor {
            operation = CKQueryOperation(cursor: cursor)
        } else {
            self.pairs.removeAll()
            if let referenceIds = referenceIds {
                let predicate : NSPredicate = NSPredicate(format: "enfocaId == %@ AND recordID IN %@", enfocaId, referenceIds)
                let sort : NSSortDescriptor = NSSortDescriptor(key: "Word", ascending: true)
                let query: CKQuery = CKQuery(recordType: "SimpleWordPair", predicate: predicate)
                query.sortDescriptors = [sort]
                operation = CKQueryOperation(query: query)
            } else {
                let predicate : NSPredicate = NSPredicate(format: "enfocaId == %@", enfocaId)
                let sort : NSSortDescriptor = NSSortDescriptor(key: "Word", ascending: true)
                let query: CKQuery = CKQuery(recordType: "SimpleWordPair", predicate: predicate)
                query.sortDescriptors = [sort]
                operation = CKQueryOperation(query: query)
            }
        }
        
        
        operation.resultsLimit = 4
        
        operation.recordFetchedBlock = {record in
            OperationQueue.main.addOperation({
                self.pairs.append(self.toWordPair(from: record))
                self.tableView.reloadData()
            })
        }
        
        operation.queryCompletionBlock = {(cursor, error) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            OperationQueue.main.addOperation({
                self.tableView.reloadData()
            })
            
            guard let cursor = cursor else {
                print("All records loaded")
                return
            }
            callback(cursor)
            
        }
        
        db.add(operation)
    }

    
    func loadCloudDataTags(callback : @escaping () -> ()){
        let sort : NSSortDescriptor = NSSortDescriptor(key: "Name", ascending: true)
        let predicate : NSPredicate = NSPredicate(format: "enfocaId == %@", enfocaId)
        
        let query: CKQuery = CKQuery(recordType: "SimpleTag", predicate: predicate)
        query.sortDescriptors = [sort]
        db.perform(query, inZoneWith: nil) { (records : [CKRecord]?, error : Error?) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let records = records, records.count > 0 else {
                print("Records is nil")
                callback() //Done
                return
            }
            
            OperationQueue.main.addOperation({
                self.tags.removeAll()
                for record in records {
                    self.tags.append(self.toTag(from: record))
                }
                self.pickerView.reloadAllComponents()
                
                callback() //Done
            })

        }

    }
    
    func cloudKitTagWordPair(wordPair : WordPair, tag: Tag){
        //load the word pair
        
        db.fetch(withRecordID: wordPair.recordId) { (record:CKRecord?, error:Error?) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let record = record else {
                print("Record is nil")
                return
            }
            
            var refList : [CKReference] = []
            
            if let list = record.value(forKey: "Tags") as? [CKReference] {
                refList.append(contentsOf: list)
            }
            
            let tagRef = CKReference(recordID: tag.recordId, action: CKReferenceAction.none)
            
            refList.append(tagRef)
            
            record.setValue(refList, forKey: "Tags")
            
            //Trevis, figuer out how to do these two saves in a single transaction
            
            self.db.save(record) { (record: CKRecord?, error: Error?) in
                if error != nil {
                    print("Error while tagging: \(error)")
                    return
                }
                print("Tagged successfully")
                OperationQueue.main.addOperation({
                    self.loadCloudDataWordPairs()
                })
            }
            
            // Now save an association record. Trevis, you did this because the associations make querrying by tag easer and you can use in on a List in iCloud (as far as you could find)
            
            let assRecord : CKRecord = CKRecord(recordType: "SimpleTagAss")
            let wordRef = CKReference(record: record, action: .none)
            assRecord.setValue(wordRef, forKey: "WordRef")
            assRecord.setValue(tagRef, forKey: "TagRef")
            assRecord.setValue(self.enfocaId, forKey: "enfocaId")
            
            
            self.db.save(assRecord) { (record: CKRecord?, error: Error?) in
                if error != nil {
                    print("Error while saving: \(error)")
                    return
                }
                print("Tag association saved successfully")
            }
            
        }
    }
    
    private func toWordPair(from record: CKRecord) -> WordPair {
        let wp = WordPair()
        wp.word = record.value(forKey: "Word") as! String!
        wp.definition = record.value(forKey: "Definition") as! String!
        wp.recordId = record.recordID
        if let tagRefs = record.value(forKey: "Tags") as? [CKReference]{
             wp.tags = findTagsWithReferences(tagReferences: tagRefs)
        }
        return wp
    }
        
    private func toTag(from record: CKRecord) -> Tag{
        let t = Tag()
        t.name = record.value(forKey: "Name") as! String!
        t.recordId = record.recordID
        return t
    }

    private func isValid(_ str : String) -> Bool {
        return !str.isEmpty
    }
    
    
}

extension ViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordPairCell")
        let wp = pairs[indexPath.row] 
        
        cell?.textLabel?.text = "\(wp.word) : \(wp.definition)"
        cell?.detailTextLabel?.text = wp.tags.description
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pairs.count
    }
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tags.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return tags[row].name
    }
}
