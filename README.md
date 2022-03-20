# assets_picker_ot

Quickly select resources from the gallery.

![show](https://xia-weiyang.github.io/gif/assets_picker_ot.gif)


``` dart
Navigator.push(context, MaterialPageRoute(builder: (_con) {
                  return PickerPage(
                    maxSelected: 3,
                    overMaxSelected: (context) {
                      debugPrint('Select up to 3 images');
                    },
                  );
                })).then((value) {
                  if (value is List<File>) {
                    // todo selected success
                  }
                });
)
```

### Thanks
[https://github.com/fluttercandies/flutter_photo_manager](https://github.com/fluttercandies/flutter_photo_manager)
