from django.test import TestCase
from rest_framework import serializers, viewsets
from database.mixins import MultiSerializerMixin, SerializerClasses

class DummySerializer(serializers.Serializer):
    pass

class AnotherDummySerializer(serializers.Serializer):
    pass

class TestViewSet(MultiSerializerMixin, viewsets.ViewSet):
    # Przykładowy ViewSet używający mixina
    default_serializer_class = DummySerializer
    serializer_classes: SerializerClasses = {
        "list": AnotherDummySerializer,
        "retrieve": DummySerializer
    }

class TestViewSetNoDefault(MultiSerializerMixin, viewsets.ViewSet):
    # Ten ViewSet nie ma default_serializer_class
    serializer_classes: SerializerClasses = {}


class MultiSerializerMixinTests(TestCase):
    def test_get_serializer_class_for_action(self):
        viewset = TestViewSet(action="list")
        serializer_class = viewset.get_serializer_class()
        self.assertEqual(serializer_class, AnotherDummySerializer)

        viewset.action = "retrieve"
        serializer_class = viewset.get_serializer_class()
        self.assertEqual(serializer_class, DummySerializer)

    def test_get_serializer_class_for_action_not_defined(self):
        # Jeżeli akcja nie jest zdefiniowana w serializer_classes
        # powinien zwrócić default_serializer_class
        viewset = TestViewSet(action="create")
        serializer_class = viewset.get_serializer_class()
        self.assertEqual(serializer_class, DummySerializer)

    def test_get_serializer_class_with_action_override(self):
        # Sprawdzenie czy podanie action_override działa poprawnie
        viewset = TestViewSet(action="list")
        serializer_class = viewset.get_serializer_class(action_override="retrieve")
        self.assertEqual(serializer_class, DummySerializer)

        # Jeśli action_override jest akcją bez zdefiniowanego serializera,
        # to powinien użyć default_serializer_class
        serializer_class = viewset.get_serializer_class(action_override="destroy")
        self.assertEqual(serializer_class, DummySerializer)

    def test_assert_no_default_serializer_class(self):
        # Ten ViewSet nie ma default_serializer_class, więc powinien rzucić AssertionError
        viewset = TestViewSetNoDefault(action="list")
        with self.assertRaises(AssertionError) as context:
            viewset.get_serializer_class()
        self.assertIn("should have assigned `default_serializer_class`", str(context.exception))

    def test_get_default_serializer_class(self):
        # Sprawdzenie czy get_default_serializer_class zwraca poprawną klasę
        viewset = TestViewSet(action="list")
        default_class = viewset.get_default_serializer_class()
        self.assertEqual(default_class, DummySerializer)
