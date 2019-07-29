//
//  TableView.PresentationState.swift
//  Listable
//
//  Created by Kyle Van Essen on 7/22/19.
//


internal extension TableView
{
    /*
     A class used to manage the "live" / mutable state of the visible rows in the table view,
     which is persistent across diffs of content (instances are only created or destroyed when a row enters or leaves the table).
     
     This is where bindings or other update-driving objects live,
     which then push the changes to the row and section content back into view models.
     */
    final class PresentationState
    {
        var sections : [PresentationState.Section] = []
        
        func row(at indexPath : IndexPath) -> TableViewPresentationStateRow
        {
            let section = self.sections[indexPath.section]
            let row = section.rows[indexPath.row]
            
            return row
        }
        
        func update(with diff : SectionedDiff<TableView.Section, TableViewRow>)
        {
            self.sections = diff.changes.transform(
                old: self.sections,
                removed: { _, _ in },
                added: { section in Section(section: section) },
                moved: { old, new, changes, section in section.update(with: old, new: new, changes: changes) },
                updated: { old, new, changes, section in section.update(with: old, new: new, changes: changes) },
                noChange: { old, new, changes, section in section.update(with: old, new: new, changes: changes) }
            )
        }
        
        final class Section
        {
            let section : TableView.Section
            
            var rows : [TableViewPresentationStateRow]
            
            init(section : TableView.Section)
            {
                self.section = section
                
                self.rows = self.section.rows.map {
                    $0.newPresentationContainer()
                }
            }
            
            func update(
                with oldSection : TableView.Section,
                new newSection : TableView.Section,
                changes : SectionedDiff<TableView.Section, TableViewRow>.RowChanges
                )
            {
                self.rows = changes.transform(
                    old: self.rows,
                    removed: { _, _ in },
                    added: { $0.newPresentationContainer() },
                    moved: { old, new, row in row.update(with: old, new: new) },
                    updated: { old, new, row in row.update(with: old, new: new) },
                    noChange: { old, new, row in row.update(with: old, new: new) }
                )
            }
        }
        
        final class Row<Element:TableViewCellElement> : TableViewPresentationStateRow
        {
            var row : TableView.Row<Element>
            
            var binding : Binding<Element>?
            
            private var visibleCell : Element.TableViewCell?
            
            init(row : TableView.Row<Element>)
            {
                self.row = row
                
                // TODO: Right now, because we do not create presentation state for rows that are
                // not part of the visible slice, we don't start watching the bound data.
                // this means that the row data can get out of date.
                
                if let binding = row.bind?(self.row.element)
                {
                    self.binding =  binding
                    
                    binding.start()

                    binding.onChange { [weak self] element in
                        guard let self = self else { return }
                        
                        self.row.element = element
                        
                        if let cell = self.visibleCell {
                            self.row.element.applyTo(cell: cell, reason: .willDisplay)
                        }
                    }
                }
            }
            
            deinit {
                self.binding?.discard()
            }
            
            // MARK: TableViewPresentationStateRow
            
            public func update(with old : TableViewRow, new : TableViewRow)
            {
                self.row = new as! TableView.Row<Element>
            }
            
            public func willDisplay(with cell : UITableViewCell)
            {
                self.visibleCell = (cell as! Element.TableViewCell)
                
                self.row.onDisplay?(self.row.element)
            }
            
            public func didEndDisplay()
            {
                self.visibleCell = nil
            }
        }
    }
}