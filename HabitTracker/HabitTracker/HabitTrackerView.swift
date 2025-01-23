import SwiftUI
import UserNotifications

struct Habit: Identifiable, Codable {
    var id: UUID?
    let name: String
    var isCompleted: Bool
    
    init(id: UUID? = nil, name: String, isCompleted: Bool = false) {
        self.id = id ?? UUID()
        self.name = name
        self.isCompleted = isCompleted
    }
}

extension UserDefaults {
    private enum Keys {
        static let habits = "habits"
    }
    
    func saveHabits(_ habits: [Habit]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(habits) {
            set(encoded, forKey: Keys.habits)
        }
    }
    
    func loadHabits() -> [Habit] {
        guard let savedHabits = object(forKey: Keys.habits) as? Data else { return [] }
        let decoder = JSONDecoder()
        if let loadedHabits = try? decoder.decode([Habit].self, from: savedHabits) {
            return loadedHabits
        }
        return []
    }
}

struct HabitTrackerView: View {
    @State private var newHabit: String = ""
    @State private var habits: [Habit] = []
    @State private var isAuthenticated: Bool = false
    
    @AppStorage("habits") private var habitsData: Data?
    
    let userDefaults = UserDefaults.standard
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("New Habit", text: $newHabit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .shadow(radius: 1)
                    
                    Button(action: addHabit) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            .shadow(radius: 3)
                    }
                }
                .padding()
                
                List {
                    ForEach(habits) { habit in
                        HStack {
                            Text(habit.name)
                                .strikethrough(habit.isCompleted, color: .gray)
                                .foregroundColor(habit.isCompleted ? .gray : .black)
                            Spacer()
                            Button(action: {
                                toggleHabitCompletion(habitID: habit.id)
                            }) {
                                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(habit.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .onDelete(perform: deleteHabit)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .onAppear {
                loadHabits()
                scheduleDailyNotifications()
            }
            .navigationTitle("Habit Tracker")
        }
    }
    
    private func addHabit() {
        guard !newHabit.isEmpty else { return }
        let habit = Habit(name: newHabit, isCompleted: false)
        habits.append(habit)
        saveHabits()
        newHabit = ""
    }
    
    private func toggleHabitCompletion(habitID: UUID?) {
        guard let habitID = habitID else { return }
        if let index = habits.firstIndex(where: { $0.id == habitID }) {
            habits[index].isCompleted.toggle()
            saveHabits()
        }
    }
    
    private func deleteHabit(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        saveHabits()
    }
    
    private func saveHabits() {
        userDefaults.saveHabits(habits)
    }
    
    private func loadHabits() {
        habits = userDefaults.loadHabits()
    }
    
    private func scheduleDailyNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                var dateComponents = DateComponents()
                dateComponents.hour = 9
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let content = UNMutableNotificationContent()
                content.title = "Habit Reminder"
                content.body = "Don't forget to complete your habits today!"
                content.sound = .default
                
                let request = UNNotificationRequest(identifier: "habitReminder", content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Notification permission not granted.")
            }
        }
    }
}

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticated: Bool = false
    @State private var loginFailed: Bool = false
    
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    
    let correctUsername = "test"
    let correctPassword = "test123"
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Login")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                TextField("Username", text: $username)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .shadow(radius: 1)
                    .onChange(of: username) {
                        usernameError = nil
                    }
                
                if let usernameError = usernameError {
                    Text(usernameError)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                SecureField("Password", text: $password)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .shadow(radius: 1)
                    .onChange(of: password) {
                        passwordError = nil
                    }

                
                if let passwordError = passwordError {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: login) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                }
                .padding()
                
                if loginFailed {
                    Text("Incorrect username or password")
                        .foregroundColor(.red)
                        .padding(.top)
                }
                
                NavigationLink("", destination: HabitTrackerView())
                    .isDetailLink(false)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .navigationDestination(isPresented: $isAuthenticated) {
                        HabitTrackerView()
                    }
            }
            .padding()
        }
    }
    
    private func login() {
        if username.isEmpty {
            usernameError = "Please enter a valid username"
        }
        
        if password.isEmpty {
            passwordError = "Please enter a valid password"
        }
        
        if !username.isEmpty && !password.isEmpty {
            if username == correctUsername && password == correctPassword {
                isAuthenticated = true
                loginFailed = false
            } else {
                loginFailed = true
            }
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
