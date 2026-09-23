# Earn Battle — Connected Flutter App

The Flutter UI is connected to the Earn Battle Node/Express backend.

## Start backend
Unzip `earn_battle_full_backend.zip`, run:
`npm install`
`npm start`

## Start Android emulator
The app uses `http://10.0.2.2:3000/api` for an Android emulator.

For a physical Android phone on the same Wi-Fi, change `baseUrl` in
`lib/main.dart` to `http://YOUR_PC_LAN_IP:3000/api`.

## Important
The JOIN flow requires a logged-in user and enough wallet balance.
This is a development integration; production payment, secure admin roles,
fraud controls and applicable paid-entry gaming compliance still need to be implemented.
