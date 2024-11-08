from rest_framework import permissions, status
from rest_framework.generics import CreateAPIView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model

from .serializers import UserSerializer
from .llm import get_structured_response, generate_suggested_links_for_user

from django.contrib.auth import get_user_model

User = get_user_model()


class CreateUserView(CreateAPIView):
    model = get_user_model()
    permission_classes = [permissions.AllowAny]
    serializer_class = UserSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        token, _ = Token.objects.get_or_create(
            user=get_user_model().objects.get(username=serializer.data["username"])
        )
        if request.data.get("user"):
            created = serializer.instance
            created.owner = get_user_model().objects.get(username=request.data["user"])
            created.is_device = True
            created.save()

        return Response(
            {**serializer.data, "token": token.key},
            status=status.HTTP_201_CREATED,
            headers=headers,
        )


class ChatGPTView(APIView):
    def post(self, request):
        prompt = request.data.get("prompt", None)
        if not prompt:
            return Response(
                {"error": "Prompt is required"}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            response = get_structured_response(
                prompt, devices=request.user.get_user_devices(), user=request.user
            )
            return Response({"response": response}, status=status.HTTP_200_OK, content_type="application/json; charset=utf-8")
        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class GenerateLinksView(APIView):
    def get(self, request):
        return Response(generate_suggested_links_for_user(request.user))
