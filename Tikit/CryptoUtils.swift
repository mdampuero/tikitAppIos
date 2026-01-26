import Foundation
import CommonCrypto

class CryptoUtils {
    // IMPORTANTE: Reemplaza esto con tu secret real del backend
    private static let SECRET = "Secreta007!"
    
    private static func deriveKey() -> Data {
        let secretData = SECRET.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        secretData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(secretData.count), &digest)
        }
        return Data(digest).prefix(32)
    }
    
    private static func deriveIV() -> Data {
        let secretData = SECRET.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        secretData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(secretData.count), &digest)
        }
        return Data(digest).prefix(16)
    }
    
    static func decrypt(_ encryptedData: String) -> String? {
        guard let data = Data(base64Encoded: encryptedData) else {
            return nil
        }
        
        let key = deriveKey()
        let iv = deriveIV()
        
        var decrypted = [UInt8](repeating: 0, count: data.count)
        var decryptedCount = Int(0)
        
        let status = data.withUnsafeBytes { encryptedBuffer in
            key.withUnsafeBytes { keyBuffer in
                iv.withUnsafeBytes { ivBuffer in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBuffer.baseAddress,
                        key.count,
                        ivBuffer.baseAddress,
                        encryptedBuffer.baseAddress,
                        data.count,
                        &decrypted,
                        decrypted.count,
                        &decryptedCount
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            print("Error desencriptando: \(status)")
            return nil
        }
        
        let decryptedData = Data(bytes: decrypted, count: Int(decryptedCount))
        return String(data: decryptedData, encoding: .utf8)
    }
}
