import Foundation
import CommonCrypto

class CryptoUtils {
    // IMPORTANTE: Reemplaza esto con tu secret real del backend (mismo que kernel.secret de Symfony)
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
        print("DEBUG CryptoUtils: Intentando desencriptar: \(encryptedData)")
        
        guard let data = Data(base64Encoded: encryptedData) else {
            print("DEBUG CryptoUtils: Error decodificando base64")
            return nil
        }
        
        print("DEBUG CryptoUtils: Base64 decodificado, longitud: \(data.count)")
        print("DEBUG CryptoUtils: Datos decodificados (hex): \(data.map { String(format: "%02x", $0) }.joined())")
        
        let key = deriveKey()
        let iv = deriveIV()
        
        print("DEBUG CryptoUtils: Key length: \(key.count), IV length: \(iv.count)")
        print("DEBUG CryptoUtils: IV derivado (hex): \(iv.map { String(format: "%02x", $0) }.joined())")
        
        var decrypted = [UInt8](repeating: 0, count: data.count + 32)
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
            print("DEBUG CryptoUtils: Error desencriptando con código: \(status)")
            return nil
        }
        
        print("DEBUG CryptoUtils: Desencriptación exitosa, datos desencriptados: \(decryptedCount) bytes")
        
        let decryptedData = Data(bytes: decrypted, count: Int(decryptedCount))
        
        let hexString = decryptedData.map { String(format: "%02x", $0) }.joined()
        print("DEBUG CryptoUtils: Bytes desencriptados (hex): \(hexString)")
        
        let result = String(data: decryptedData, encoding: .utf8)
        
        print("DEBUG CryptoUtils: Resultado desencriptado: \(result ?? "nil")")
        
        return result
    }
}
