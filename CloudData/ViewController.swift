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
 Implement pagination
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
                    completion(nil)
                    return
                }
                completion(id)
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
        let predicate : NSPredicate = NSPredicate(format: "enfocaId = %@", enfocaId)
        let sort : NSSortDescriptor = NSSortDescriptor(key: "Word", ascending: true)
        let query: CKQuery = CKQuery(recordType: "SimpleWordPair", predicate: predicate)
        query.sortDescriptors = [sort]
        
        
        //Trevis.  CKQuery operation takes a query or a cursor.  I believe that the cursor allows your pagination functionality.  
        // take a look at the use of CKQueryOperation in this tutorial
        //https://www.hackingwithswift.com/read/33/6/reading-from-icloud-with-cloudkit-ckqueryoperation-and-nspredicate
        
//        let qop = CKQueryOperation(query: query)
//        qop.resultsLimit = 2
        
        db.perform(query, inZoneWith: nil) { (records : [CKRecord]?, error : Error?) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let records = records, records.count > 0 else {
                print("Records is nil")
                return
            }
            
            OperationQueue.main.addOperation({
                self.pairs.removeAll()
                
                for record in records {
                    self.pairs.append(self.toWordPair(from: record))
                }
                self.tableView.reloadData()
            })
        }
    }
    
    func loadCloudDataWordPairs(with tags : [Tag]){
        //CKRecordID's should be querried with CKReferences.
        let tagRefs : [CKReference] = tags.map { (tag: Tag) -> CKReference in
            return CKReference(recordID: tag.recordId, action: .none)
        }
        
//        let predicate : NSPredicate = NSPredicate(format: "tags IN %@", argumentArray: tagIds)
//        let predicate : NSPredicate = NSPredicate(format: "tags IN %@", tagIds[0])
//        let predicate : NSPredicate = NSPredicate(format: "tagRef IN %@", argumentArray: tagIds)
//        let predicate : NSPredicate = NSPredicate(format: "TagRef == %@", tagIds[0]) 
        
//        let predicate : NSPredicate = NSPredicate(format: "TagRef == %@", argumentArray: tagIds)
        
//        let predicate : NSPredicate = NSPredicate(format: "TagRef in %@", tagRefs)
        
        let predicate : NSPredicate = NSPredicate(format: "enfocaId == %@ AND TagRef in %@", enfocaId, tagRefs)
//        let sort : NSSortDescriptor = NSSortDescriptor(key: "Word", ascending: true)
        let query: CKQuery = CKQuery(recordType: "SimpleTagAss", predicate: predicate)
//        query.sortDescriptors = [sort]
        db.perform(query, inZoneWith: nil) { (records : [CKRecord]?, error : Error?) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let records = records, records.count > 0 else {
                print("Records is nil")
                return
            }
            
            var recordIds : [CKReference] = []
            for record in records {
                let wordRef = record.value(forKey: "WordRef") as! CKReference
                recordIds.append(wordRef)
            }
            
            self.loadCloudDataWordPairs(recordIds : recordIds)
        }
    }
    
    func loadCloudDataWordPairs(recordIds : [CKReference]){
        
//        https://developer.apple.com/reference/cloudkit/ckquery#//apple_ref/occ/cl/CKQuery
//        http://stackoverflow.com/questions/32900235/how-to-query-cloudkit-for-recordid-in-ckrecordid
        
        let predicate : NSPredicate = NSPredicate(format: "recordID IN %@", recordIds)
        
        self.pairs.removeAll()
        
        let sort : NSSortDescriptor = NSSortDescriptor(key: "Word", ascending: true)
        let query: CKQuery = CKQuery(recordType: "SimpleWordPair", predicate: predicate)
        query.sortDescriptors = [sort]
        
        db.perform(query, inZoneWith: nil) { (records : [CKRecord]?, error : Error?) in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let records = records, records.count > 0 else {
                print("Records is nil")
                return
            }
            
            OperationQueue.main.addOperation({
                for record in records {
                    self.pairs.append(self.toWordPair(from: record))
                }
                self.tableView.reloadData()
            })
        }
    }

    
    
    func loadCloudDataTags(callback : @escaping () -> ()){
//        let predicate : NSPredicate = NSPredicate(value: true)
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
