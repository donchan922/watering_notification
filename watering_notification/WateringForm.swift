//
//  WateringForm.swift
//  watering_notification
//
//  Created by donchan922 on 2020/05/09.
//  Copyright © 2020 Daiki Tsukuda. All rights reserved.
//

import SwiftUI
import CoreData
import UserNotifications

struct WateringForm: View {
    @Binding var isShowingModal: Bool
    @Environment(\.managedObjectContext) var context
    @State private var plantName = ""
    @State private var term = 1
    @State private var nextTime = Date()
    @State private var icon = "plant_01"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("植物の名前")) {
                    TextField("", text: $plantName)
                }
                Section(header: Text("水やりの間隔")) {
                    Picker(selection: $term, label: Text("")) {
                        ForEach(1...100, id: \.self) { index in
                            Text("\(index)日ごと")
                        }
                    }
                }
                Section(header: Text("水やりの時間")) {
                    DatePicker(selection: $nextTime, displayedComponents: [.hourAndMinute]) {
                        Text("")
                    }
                }
                Section(header: Text("アイコン")) {
                    VStack {
                        HStack {
                            IconImage(icon: $icon, iconName: "plant_01")
                            IconImage(icon: $icon, iconName: "plant_02")
                            IconImage(icon: $icon, iconName: "plant_03")
                            IconImage(icon: $icon, iconName: "plant_04")
                        }
                        HStack {
                            IconImage(icon: $icon, iconName: "plant_05")
                            IconImage(icon: $icon, iconName: "plant_06")
                            IconImage(icon: $icon, iconName: "plant_07")
                            IconImage(icon: $icon, iconName: "plant_08")
                        }
                        HStack {
                            IconImage(icon: $icon, iconName: "plant_09")
                            IconImage(icon: $icon, iconName: "plant_10")
                            IconImage(icon: $icon, iconName: "plant_11")
                            IconImage(icon: $icon, iconName: "plant_12")
                        }
                    }
                }
            }
            .navigationBarTitle(Text("登録内容"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    self.isShowingModal.toggle()
                }) {
                    Text("キャンセル")
                },
                trailing: Button(action: {
                    self.addWatering()
                    self.isShowingModal.toggle()
                }) {
                    Text("完了")
                }.disabled(plantName.isEmpty)
            )
        }
    }
    
    func addWatering() {
        let uuid = UUID()
        let nextTime = Calendar.current.date(byAdding: .day, value: self.term, to: self.nextTime)!

        // save data
        let watering = Watering(context: context)
        watering.id = uuid
        watering.plantName = plantName
        watering.term = Int16(term)
        watering.nextTime = nextTime
        watering.icon = icon
        watering.createdAt = Date()
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        // set notification
        let content = UNMutableNotificationContent()
        content.title = "🌱水やりのお知らせ"
        content.body = "\(plantName)に水やりする時間です"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Date().distance(to: nextTime), repeats: true)
        let request = UNNotificationRequest(identifier: uuid.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct WateringForm_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return WateringForm(isShowingModal: .constant(true)).environment(\.managedObjectContext, context)
    }
}
