//
//  ViewController.swift
//  TodoList-CoreData
//
//  Created by Ahmed Abaza on 26/02/2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController {
    
    // MARK: -Properties
    private(set) var dataContext: NSManagedObjectContext?
    
    private(set) var listItems: [TodoItem] = [] {
        didSet {
            DispatchQueue.main.async {
                self.listTableView.reloadData()
            }
        }
    }
    
    
    // MARK: -Outlets
    @IBOutlet weak var listTableView: UITableView! {
        didSet {
            listTableView.dataSource = self
            listTableView.delegate = self
        }
    }
    
    
    
    //MARK: -Actions
    @IBAction func didTapNewItem(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "New Item", message: "Enter title", preferredStyle: .alert)
        
        // defining alert actions
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let titleField = alertController.textFields?.first,
                  let subtitleField = alertController.textFields?[1],
                  let title = titleField.text, let subtitle = subtitleField.text, !title.isEmpty else { return }
            
            // save the item and relaod the data
            self?.createNewListItem(title: title, subtitle: subtitle)
            self?.getAllItems(completion: { items in
                guard let items = items else { return }
                self?.listItems = items
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        
        // adding text field to the alert
        alertController.addTextField()
        alertController.addTextField()
        
        // adding actions
        alertController.addActions([addAction, cancelAction])
        
        self.present(alertController, animated: true)
    }
    
    
    

    // MARK: -LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareDataContext()
        
        self.getAllItems { [weak self] items in
            guard let items = items else { return }
            self?.listItems = items
        }
    }
    
    
    
    // MARK: -Functions
    ///Safely prepares the persistent container's context.
    private func prepareDataContext() -> Void {
        guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else { return }
        self.dataContext = appDelegate.persistentContainer.viewContext
    }
    
    
    private func createNewListItem(title: String, subtitle: String = .emptyString) -> Void {
        guard let dataContext = dataContext else { return }
        
        let newItem = TodoItem(context: dataContext)
        
        newItem.title = title
        newItem.subtitle = subtitle
        newItem.addingTime = Date()
        
        do {
            try dataContext.save()
        } catch let error {
            print("Create New Item Error: \(error)")
        }
    }
    
    private func updateListItem(_ item: TodoItem ,title: String, subtitle: String = .emptyString, completion: (_ isSuccessful: Bool) -> Void) -> Void {
        guard let dataContext = dataContext else { completion(false); return }
        
        item.title = title
        item.subtitle = subtitle
        
        do {
            try dataContext.save()
            completion(true)
        } catch let error {
            print("Delete Item Error: \(error)")
            completion(false)
        }
    }
    
    private func deleteListItem(_ item: TodoItem, completion: (_ isSuccessful: Bool) -> Void) -> Void {
        guard let dataContext = dataContext else { completion(false); return }
        
        dataContext.delete(item)
        
        do {
            try dataContext.save()
            completion(true)
        } catch let error {
            print("Delete Item Error: \(error)")
            completion(false)
        }
    }
    
    private func getAllItems(completion: ((_ items: [TodoItem]?) -> Void)? = nil) -> Void {
        guard let dataContext = dataContext else { completion?(nil); return }
        
        do {
            let items =  try dataContext.fetch(TodoItem.fetchRequest())
            completion?(items)
        } catch let error {
            print("Get Items Error: \(error)")
            completion?(nil)
        }
    }
    
    private func getItem() -> Void {
        
    }

}

// MARK: -Associated Extensions

extension String {
    static let emptyString = ""
}

extension UIAlertController {
    func addActions(_ actions: [UIAlertAction]) -> Void {
        actions.forEach { action in
            self.addAction(action)
        }
    }
}


extension ListViewController {
    struct ControllerConsts {
        static let todoCellId: String = "todoCell"
    }
}

// MARK: -TableView Delegate & DataSource
extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.listItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ControllerConsts.todoCellId, for: indexPath)
        let listItemForCell = self.listItems[indexPath.row]
        
        var contentConfig = cell.defaultContentConfiguration()
        
        contentConfig.text = listItemForCell.title
        contentConfig.secondaryText = listItemForCell.subtitle
        
        cell.contentConfiguration = contentConfig
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //TODO: Show sheet actions..
        let itemForAction = self.listItems[indexPath.row]
        let actionSheet = UIAlertController(title: "Item Actions", message: "You can edit or delete...", preferredStyle: .actionSheet)
        
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteListItem(itemForAction, completion: { isSuccessful in
                guard isSuccessful else { return }
                self?.getAllItems(completion: { items in
                    guard let items = items else { return }
                    self?.listItems = items
                })
            })
        }
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
            print("Will do the update later... sorry! ;{")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            actionSheet.dismiss(animated: true, completion: nil)
        }
        
        actionSheet.addActions([deleteAction, updateAction, cancelAction])
        
        self.present(actionSheet, animated: true)
    }
}

