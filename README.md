# capsule2024

This is a Flutter project to showcase the [Capsule2024](https://capsule2024.com/) application. It is an app to interact with the Capsule locally or remotly.

## Notification mqtt gateway

The app can send a notification when a new subtopic in the parent topic "notification/" is received.
In order to send notifications to the user you must then send a message to the topic "notification/<title_of_the_notif>"
