//
//  SwiftContactTool.swift
//  ContactExperiment
//
//  Created by Martini Wang on 14/11/5.
//  Copyright (c) 2014年 Martini Wang. All rights reserved.
//

/*
1. 需要项目引入Address框架
2. 主函数getSysContacts()返回经过解析的数组，每个联系人的信息为一个字典
3. 调用方式：let sysContacts:Array = getSysContacts()
4. 输出（Xcode6.1模拟器通讯录）：

_$!<Home>!$_Phone: 555-610-6679
FirstName: David
FirstNamePhonetic:
_$!<Home>!$_Address_Contrycode: us
Department:
_$!<Home>!$_Address_City: Tiburon
_$!<Home>!$_Address_State: CA
_$!<Home>!$_Address_Country: USA
Note: Plays on Cole's Little League Baseball Team

LirstNamePhonetic:
Organization:
Nikename:
_$!<Home>!$_Address_Street: 1747 Steuart Street
fullAddress: USA, CA, Tiburon, 1747 Steuart Street
LastName: Taylor
JobTitle:
fullName: David Taylor
---------

*/

import Foundation
import AddressBook
import AddressBookUI

func getSysContacts() -> [[String:String]] {
    var error:Unmanaged<CFError>?
    var addressBook: ABAddressBookRef? = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
    
    let sysAddressBookStatus = ABAddressBookGetAuthorizationStatus()
    
    if sysAddressBookStatus == .Denied || sysAddressBookStatus == .NotDetermined {
        // Need to ask for authorization
        var authorizedSingal:dispatch_semaphore_t = dispatch_semaphore_create(0)
        var askAuthorization:ABAddressBookRequestAccessCompletionHandler = { success, error in
            if success {
                ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as NSArray
                dispatch_semaphore_signal(authorizedSingal)
            }
        }
        ABAddressBookRequestAccessWithCompletion(addressBook, askAuthorization)
        dispatch_semaphore_wait(authorizedSingal, DISPATCH_TIME_FOREVER)
    }
    
    func analyzeSysContacts(sysContacts:NSArray) -> [[String:String]] {
        var allContacts:Array = [[String:String]]()
        
        func analyzeContactProperty(contact:ABRecordRef, property:ABPropertyID, keySuffix:String) -> [String:String]? {
            var propertyValues:ABMultiValueRef? = ABRecordCopyValue(contact, property)?.takeRetainedValue()
            if propertyValues != nil {
                //var values:NSMutableArray = NSMutableArray()
                var valueDictionary:Dictionary = [String:String]()
                for i in 0 ..< ABMultiValueGetCount(propertyValues) {
                    var label:String = ABMultiValueCopyLabelAtIndex(propertyValues, i).takeRetainedValue() as String
                    label += keySuffix
                    var value = ABMultiValueCopyValueAtIndex(propertyValues, i)
                    switch property {
                        // 地址
                    case kABPersonAddressProperty :
                        var addrNSDict:NSMutableDictionary = value.takeRetainedValue() as NSMutableDictionary
                        valueDictionary[label+"_Country"] = addrNSDict.valueForKey(kABPersonAddressCountryKey) as? String ?? ""
                        valueDictionary[label+"_State"] = addrNSDict.valueForKey(kABPersonAddressStateKey) as? String ?? ""
                        valueDictionary[label+"_City"] = addrNSDict.valueForKey(kABPersonAddressCityKey) as? String ?? ""
                        valueDictionary[label+"_Street"] = addrNSDict.valueForKey(kABPersonAddressStreetKey) as? String ?? ""
                        valueDictionary[label+"_Contrycode"] = addrNSDict.valueForKey(kABPersonAddressCountryCodeKey) as? String ?? ""
                        
                        // 地址整理
                        valueDictionary["fullAddress"] = (valueDictionary[label+"_Country"]! == "" ? valueDictionary[label+"_Contrycode"]! : valueDictionary[label+"_Country"]!) + ", " + valueDictionary[label+"_State"]! + ", " + valueDictionary[label+"_City"]! + ", " + valueDictionary[label+"_Street"]!
                        // SNS
                    case kABPersonSocialProfileProperty :
                        var snsNSDict:NSMutableDictionary = value.takeRetainedValue() as NSMutableDictionary
                        valueDictionary[label+"_Username"] = snsNSDict.valueForKey(kABPersonSocialProfileUsernameKey) as? String ?? ""
                        valueDictionary[label+"_URL"] = snsNSDict.valueForKey(kABPersonSocialProfileURLKey) as? String ?? ""
                        valueDictionary[label+"_Serves"] = snsNSDict.valueForKey(kABPersonSocialProfileServiceKey) as? String ?? ""
                        // IM
                    case kABPersonInstantMessageProperty :
                        var imNSDict:NSMutableDictionary = value.takeRetainedValue() as NSMutableDictionary
                        valueDictionary[label+"_Serves"] = imNSDict.valueForKey(kABPersonInstantMessageServiceKey) as? String ?? ""
                        valueDictionary[label+"_Username"] = imNSDict.valueForKey(kABPersonInstantMessageUsernameKey) as? String ?? ""
                        // Date
                    case kABPersonDateProperty :
                        valueDictionary[label] = (value.takeRetainedValue() as? NSDate)?.description
                    default :
                        valueDictionary[label] = value.takeRetainedValue() as? String ?? ""
                    }
                }
                return valueDictionary
            }else{
                return nil
            }
        }
        
        for contact in sysContacts {
            var currentContact:Dictionary = [String:String]()
            
            /*
            部分单值属性
            */
            // 姓、姓氏拼音
            currentContact["FirstName"] = ABRecordCopyValue(contact, kABPersonFirstNameProperty)?.takeRetainedValue() as String? ?? ""
            currentContact["FirstNamePhonetic"] = ABRecordCopyValue(contact, kABPersonFirstNamePhoneticProperty)?.takeRetainedValue() as String? ?? ""
            // 名、名字拼音
            currentContact["LastName"] = ABRecordCopyValue(contact, kABPersonLastNameProperty)?.takeRetainedValue() as String? ?? ""
            currentContact["LirstNamePhonetic"] = ABRecordCopyValue(contact, kABPersonLastNamePhoneticProperty)?.takeRetainedValue() as String? ?? ""
            // 昵称
            currentContact["Nikename"] = ABRecordCopyValue(contact, kABPersonNicknameProperty)?.takeRetainedValue() as String? ?? ""
            
            // 姓名整理
            currentContact["fullName"] = currentContact["FirstName"]! + " " + currentContact["LastName"]!
            
            // 公司（组织）
            currentContact["Organization"] = ABRecordCopyValue(contact, kABPersonOrganizationProperty)?.takeRetainedValue() as String? ?? ""
            // 职位
            currentContact["JobTitle"] = ABRecordCopyValue(contact, kABPersonJobTitleProperty)?.takeRetainedValue() as String? ?? ""
            // 部门
            currentContact["Department"] = ABRecordCopyValue(contact, kABPersonDepartmentProperty)?.takeRetainedValue() as String? ?? ""
            // 备注
            currentContact["Note"] = ABRecordCopyValue(contact, kABPersonNoteProperty)?.takeRetainedValue() as String? ?? ""
            // 生日（类型转换有问题，不可用）
            //currentContact["Brithday"] = ((ABRecordCopyValue(contact, kABPersonBirthdayProperty)?.takeRetainedValue()) as NSDate).description
            
            /*
            部分多值属性
            */
            // 电话
            for (key, value) in analyzeContactProperty(contact, kABPersonPhoneProperty,"Phone") ?? ["":""] {
                currentContact[key] = value
            }
            // E-mail
            for (key, value) in analyzeContactProperty(contact, kABPersonEmailProperty, "Email") ?? ["":""] {
                currentContact[key] = value
            }
            // 地址
            for (key, value) in analyzeContactProperty(contact, kABPersonAddressProperty, "Address") ?? ["":""] {
                currentContact[key] = value
            }
            // 纪念日
            for (key, value) in analyzeContactProperty(contact, kABPersonDateProperty, "Date") ?? ["":""] {
                currentContact[key] = value
            }
            // URL
            for (key, value) in analyzeContactProperty(contact, kABPersonURLProperty, "URL") ?? ["":""] {
                currentContact[key] = value
            }
            // SNS
            for (key, value) in analyzeContactProperty(contact, kABPersonSocialProfileProperty, "_SNS") ?? ["":""] {
                currentContact[key] = value
            }
            
            allContacts.append(currentContact)
        }
        
        return allContacts
    }
    
    return analyzeSysContacts( ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as NSArray )
}