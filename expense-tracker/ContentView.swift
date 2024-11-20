import SwiftUI

// MARK: - Model
struct Expense: Identifiable, Codable {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
}

// MARK: - ViewModel
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = [] {
        didSet {
            saveExpenses()
        }
    }
    
    init() {
        loadExpenses()
    }
    
    private let userDefaultsKey = "ExpensesKey"
    
    func addExpense(id: UUID = UUID(), title: String, amount: Double, date: Date = Date()) {
        let newExpense = Expense(id: id, title: title, amount: amount, date: date)
        expenses.append(newExpense)
    }

    
    func updateExpense(expense: Expense, title: String, amount: Double) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index].title = title
            expenses[index].amount = amount
        }
    }
    
    func removeExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
    }
    
    private func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var showAddEditExpenseView = false
    @State private var selectedExpense: Expense? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.expenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.title)
                                    .font(.headline)
                                Text("\(expense.amount, specifier: "%.2f") USD")
                                    .foregroundColor(.secondary)
                                Text(expense.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                selectedExpense = expense
                                showAddEditExpenseView = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete { offsets in
                        viewModel.removeExpense(at: offsets)
                    }
                }
                .listStyle(InsetGroupedListStyle())

                Button(action: {
                    selectedExpense = nil
                    showAddEditExpenseView = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Expense")
                            .fontWeight(.bold)
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Expense Tracker")
            .sheet(isPresented: $showAddEditExpenseView) {
                AddEditExpenseView(
                    viewModel: viewModel,
                    expenseToEdit: selectedExpense
                )
            }
        }
    }
}




// MARK: - Add/Edit Expense View
struct AddEditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ExpenseViewModel
    var expenseToEdit: Expense?
    @State private var title = ""
    @State private var amount = ""
    
    var isEditing: Bool {
        expenseToEdit != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Icon Header
                    VStack(spacing: 10) {
                        Image(systemName: isEditing ? "square.and.pencil" : "plus.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)
                        
                        Text(isEditing ? "Edit Expense" : "Add Expense")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Custom Input Fields
                    VStack(spacing: 15) {
                        TextField("Enter Title", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
                        
                        TextField("Enter Amount", text: $amount)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        guard let amount = Double(amount), !title.isEmpty else { return }
                        
                        if isEditing {
                            viewModel.updateExpense(expense: expenseToEdit!, title: title, amount: amount)
                        } else {
                            viewModel.addExpense(title: title, amount: amount)
                        }
                        dismiss()
                    }) {
                        Text(isEditing ? "Update Expense" : "Save Expense")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .disabled(title.isEmpty || amount.isEmpty)
                }
                .padding(.vertical, 40)
            }
            .onAppear {
                if let expense = expenseToEdit {
                    title = expense.title
                    amount = "\(expense.amount)"
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
