# wick-ui

**WAMP API Tester — Cross-platform**  
_Postman for WAMP_

---

**wick-ui** is a cross-platform developer tool for interacting with WAMP APIs and routers. It allows you to create routers, connect clients, and test WAMP procedures in real time — just like Postman, but purpose-built for WAMP.

Built with Flutter, it supports **desktop**, **web**, and **mobile** platforms.

---

## 📦 Features

- 🔌 Create & run WAMP routers (in-app)
- 🤖 Connect WAMP clients to local or external routers
- 🖥️ Tabbed interface with persistent session state
- 🔐 Support for WAMP authenticators:
    - Anonymous
    - Ticket
    - WAMP-CRA
    - Cryptosign
- 🌐 Transport support:
    - `ws`, `wss`
- ⚙️ Call RPCs, register procedures, subscribe to topics, and publish events
- 🧾 Realtime structured logs (results, errors)
- 🧰 Modular router/client config system
- 🧠 Session persistence and automatic reuse
---

## 🧭 Usage Guide

> ⚠️ **Before creating clients or running WAMP actions, make sure a router is running.**  
You can:
- 🛠️ Create and start a router inside wick-ui via the "Routers" screen
- 🌐 Connect to an external router like xconn-router or Crossbar.io

---

### 🔌 Routers Screen

Manage reusable WAMP router configurations.

- ➕ **Create Router**:
    - Set realm, port and serializer (`json`, `msgpack`, etc.)

- 🔌 **Run Router**:
    - You can toggle the router to start it in-app
    - The app manages local lifecycle
---

### 🤖 Clients Screen

Create and manage WAMP session clients.

#### ➕ Create New Client

- **Client Name**: Friendly label
- **URI**: Points to local or external router
    - Example: `ws://localhost:8080/ws`
- **Realm**: The WAMP realm to join
- **Serializer**: `json`, `msgpack`, etc.
- **Auth ID**: `john`
- **Auth Method**: anonymous, ticket, wampcra, cryptosign

#### 🔌 Connect

- Initializes a WAMP session
- Reuses session across tabs if already active
- The session becomes available in the **Actions** screen

---



#### 🔎 Logs Panel

- Live updates for results, errors, and event payloads
---

## 📂 Session Persistence

- WAMP clients remain active across tabs and routes
- Tabs retain their session
- Ideal for parallel testing and long-running connections

---

## 🧰 Tech Stack

- Flutter – UI and multi-platform support
- GetX – State management and dependency injection
- [xconn-dart](https://github.com/xconnio/xconn-dart) for WAMP communication in Dart.
---

## 🔧 Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install)

## 🚀 Run Locally

```bash
git clone https://github.com/xconnio/wick-ui.git
cd wick-ui
flutter pub get
flutter run -d linux  # or: windows, macos, chrome, android, ios