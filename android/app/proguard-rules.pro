
-keep class com.follow.clash.models.**{ *; }

-keep class com.follow.clash.service.models.**{ *; }

# NOTE: 保护 JNI 接口和 native 方法不被 R8 重命名或移除。
-keep class com.follow.clash.core.** { *; }
-keep class com.follow.clash.core.Core { *; }