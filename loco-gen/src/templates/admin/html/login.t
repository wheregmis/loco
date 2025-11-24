to: assets/views/admin/login.html
skip_exists: true
message: "Admin login page was added successfully."
---
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Admin Login</title>
  <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio,line-clamp"></script>
</head>
<body class="min-h-screen bg-gray-100 flex items-center justify-center">
  <div class="w-full max-w-md bg-white shadow rounded-lg p-8">
    <div class="text-center mb-6">
      <h1 class="text-2xl font-bold">Admin Panel</h1>
      <p class="text-gray-500">Sign in to continue</p>
    </div>

    {% raw %}{% if error %}{% endraw %}
      <div class="mb-4 rounded border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
        {% raw %}{{ error }}{% endraw %}
      </div>
    {% raw %}{% endif %}{% endraw %}

    <form method="post" action="{{prefix}}/login" class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1" for="username">Username</label>
        <input
          id="username"
          type="text"
          name="username"
          value="{% raw %}{{ username | default(value="") }}{% endraw %}"
          class="w-full rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:ring-blue-500"
          required
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1" for="password">Password</label>
        <input
          id="password"
          type="password"
          name="password"
          class="w-full rounded border border-gray-300 px-3 py-2 focus:border-blue-500 focus:ring-blue-500"
          required
        />
      </div>

      <button
        type="submit"
        class="w-full rounded bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700"
      >
        Sign In
      </button>
    </form>
  </div>
</body>
</html>
