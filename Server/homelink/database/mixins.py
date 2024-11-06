from typing_extensions import NotRequired
from typing import TypedDict

from rest_framework import serializers, viewsets


class SerializerClasses(TypedDict):
    create: NotRequired[serializers.SerializerMetaclass]
    retrieve: NotRequired[serializers.SerializerMetaclass]
    update: NotRequired[serializers.SerializerMetaclass]
    partial_update: NotRequired[serializers.SerializerMetaclass]
    destroy: NotRequired[serializers.SerializerMetaclass]
    list: NotRequired[serializers.SerializerMetaclass]


class MultiSerializerMixin(viewsets.ViewSetMixin):
    default_serializer_class: serializers.SerializerMetaclass = None  # type: ignore

    serializer_classes: SerializerClasses = {}

    def get_serializer_class(self, action_override=None):
        return self.serializer_classes.get(
            self.action if action_override is None else action_override,
            self.get_default_serializer_class(),
        )

    def get_default_serializer_class(self):
        assert (
            self.default_serializer_class is not None
        ), f"{self.__class__.__name__} should have assigned `default_serializer_class`"

        return self.default_serializer_class
