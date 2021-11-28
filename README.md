# TitechPortalKit

Titech Portal Login Tools for swift.

## Usage

```swift
let username = "00B00000"
let password = "password"
let matrixcode: [TitechPortalMatrix: String] = [
    .a1: "A",
    .a2: "B",
    .a3: "B",
    .a4: "B",
    .a5: "B",
    ...
]

let portal = TitechPortal(urlSession: .shared)

Task {
    do {
        try await portal.login(
            account: TitechPortalAccount(
                username: username,
                password: password,
                matrixcode: matrixcode
            )
        )
        exit(0)
    } catch {
        print(error)
        exit(1)
    }
}

dispatchMain()
```
