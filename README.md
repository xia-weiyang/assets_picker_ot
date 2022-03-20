# assets_picker_ot

Simple and easy to implement your markdown editor, it uses its own parser.

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
