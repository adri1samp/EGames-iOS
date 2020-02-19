import Foundation

class HttpClient {
    static let base = "https://informatica.ieszaidinvergeles.org:9061/egames/api/"

    class func delete(_ route: String, _ callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        return request(route, "delete", nil, callBack)
    }

    class func delete(_ route: String, _ callBack: @escaping ((Data?) -> Void)) -> Bool {
        return request(route, "delete", nil, callBack)
    }

    class func dict2Json(_ data: [String:Any]) -> Data? {
        guard let json = try? JSONSerialization.data(withJSONObject: data as Any, options: []) else {
            return nil
        }
        return json
    }

    class func get(_ route: String, _ callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        return request(route, "get", nil, callBack)
    }

    class func get(_ route: String, _ callBack: @escaping ((Data?) -> Void)) -> Bool {
        return request(route, "get", nil, callBack)
    }

    class func post(_ route: String, _ data: [String:Any], _ callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        return request(route, "post", data, callBack)
    }

    class func post(_ route: String, _ data: [String:Any], _ callBack: @escaping ((Data?) -> Void)) -> Bool {
        return request(route, "post", data, callBack)
    }

    class func put(_ route: String, _ data: [String:Any], _ callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        return request(route, "put", data, callBack)
    }

    class func put(_ route: String, _ data: [String:Any], _ callBack: @escaping ((Data?) -> Void)) -> Bool {
        return request(route, "put", data, callBack)
    }

    class func request(_ route: String, _ method: String, _ callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        return request(route, method, nil, callBack)
    }

    class func request(_ route: String, _ method: String, _ callBack: @escaping ((Data?) -> Void)) -> Bool {
        return request(route, method, nil, callBack)
    }

    class func request(_ route: String, _ method: String, _ data: [String:Any]?, _ callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        let sesion = URLSession(configuration: URLSessionConfiguration.default)
        guard let url = URL(string: base + route) else {
            return false
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type") //añadir cabecera para funcionar
        if method != "get" && data != nil { //si no se indica que van en formato json laravel piensa que se manda en urlCodex
            guard let diccionario = dict2Json(data!) else {
                return false
            }
            urlRequest.httpBody = diccionario
        }
        let task = sesion.dataTask(with: urlRequest, completionHandler: callBack)
        task.resume()
        return true
    }

    class func request(_ route: String, _ method: String, _ data: [String:Any]?, _ callBack: @escaping ((Data?) -> Void)) -> Bool {
        return request(route, method, data) { (data, response, error) in
            if response == nil || error != nil || data == nil {
                callBack(nil)
            } else {
                if let printData = String(data: data!, encoding: .utf8) {
                    print(printData)
                }
                callBack(data!)
            }
        }
    }

    class func upload(route: String, fileParameter: String, fileName: String, fileData: Data, callBack: @escaping ((Data?, URLResponse?, Error?) -> Void)) -> Bool {
        let sesion = URLSession(configuration: URLSessionConfiguration.default)
        guard let url = URL(string: base + route) else {
            return false
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "post"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fileParameter)\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: application/octet-stream\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))
        urlRequest.httpBody = body
        
        let task = sesion.dataTask(with: urlRequest) { (data, response, error) in
            if response == nil || error != nil || data == nil {
                callBack(nil, nil, nil)
            }
            else {
                callBack(data!, response, error)
            }
        }
        task.resume()
        return true
    }
}
