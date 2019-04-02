//
//  MRZScanResult.swift
//  EmiratesIDMRZScanner
//
//  Created by Faris Abu Saleem on 4/2/19.
//

import Foundation
import QKMRZParser

public class MRZScanResult {
    public let documentImage: UIImage
    public let documentType: String
    public let countryCode: String
    public let surnames: String
    public let givenNames: String
    public let documentNumber: String
    public let nationality: String
    public let birthDate: Date?
    public let sex: String?
    public let expiryDate: Date?
    public let personalNumber: String
    public let personalNumber2: String?
    
    init(mrzResult: QKMRZResult, documentImage image: UIImage) {
        documentImage = image
        documentType = mrzResult.documentType
        countryCode = mrzResult.countryCode
        surnames = mrzResult.surnames
        givenNames = mrzResult.givenNames
        documentNumber = mrzResult.documentNumber
        nationality = mrzResult.nationality
        birthDate = mrzResult.birthDate
        sex = mrzResult.sex
        expiryDate = mrzResult.expiryDate
        personalNumber = mrzResult.personalNumber
        personalNumber2 = mrzResult.personalNumber2
    }
}
