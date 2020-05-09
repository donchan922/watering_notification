//
//  ContentView.swift
//  watering_notification
//
//  Created by donchan922 on 2020/05/09.
//  Copyright © 2020 Daiki Tsukuda. All rights reserved.
//

import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Watering.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Watering.createdAt, ascending: true)]
    ) var waterings: FetchedResults<Watering>
    @State private var isShowingModal = false
    
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEach(waterings, id: \.self.id) { watering in
                        NavigationLink(destination: WateringDetail(watering: watering)) {
                            HStack {
                                Image(watering.icon ?? "")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(watering.plantName ?? "")
                                        .fontWeight(.bold)
                                    Text("\(watering.term)日ごと\(self.formatDateToTimeStyle(date: watering.nextTime ?? Date()))に水やりする")
                                    Text("次回の水やりは\(self.formatDateToDayOfTheWeekStyle(date: watering.nextTime ?? Date()))")
                                }
                            }
                            
                        }
                    }
                    .onDelete(perform: deleteWatering)
                    .padding(.vertical)
                }
                .navigationBarTitle(Text("水やりする植物一覧"), displayMode: .inline)
                .navigationBarItems(trailing: HStack {
                    Button(action: {
                        self.isShowingModal.toggle()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("追加")
                        }
                        .foregroundColor(.green)
                        .font(.headline)
                    }.sheet(isPresented: $isShowingModal) {
                        WateringForm(isShowingModal: self.$isShowingModal)
                            .environment(\.managedObjectContext, self.context)
                    }
                })
            }
        }
        .onAppear(perform: {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (_, _) in
            }
            self.updateNextWateringTime()
        })
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.updateNextWateringTime()
        }
    }
    
    func formatDateToTimeStyle(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.amSymbol = .none
        return dateFormatter.string(from: date)
    }
    
    func formatDateToDayOfTheWeekStyle(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "M/d (EEE)"
        return dateFormatter.string(from: date)
    }
        
    func deleteWatering(offsets: IndexSet) {
        for index in offsets {
            // delete notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [waterings[index].id!.uuidString])

            // delete data
            context.delete(waterings[index])
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func updateNextWateringTime() {
        let now = Date()

        waterings.forEach({ watering in
            // update data
            if watering.nextTime! > now {
                return
            }
            while (true) {
                watering.nextTime = Calendar.current.date(byAdding: .day, value: Int(watering.term), to: watering.nextTime!)!
                if watering.nextTime! > now {
                    break
                }
            }
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            // update notification
            let content = UNMutableNotificationContent()
            content.title = "🌱水やりのお知らせ"
            content.body = "\(watering.plantName!)に水やりする時間です"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Date().distance(to: watering.nextTime!), repeats: true)
            let request = UNNotificationRequest(identifier: watering.id!.uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
