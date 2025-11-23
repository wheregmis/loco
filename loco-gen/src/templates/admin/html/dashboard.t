to: assets/views/admin/dashboard.html
skip_exists: true
message: "Admin dashboard view was added successfully."
---
{% raw %}{% extends "admin/base.html" %}{% endraw %}

{% raw %}{% block title %}Admin Dashboard{% endblock title %}{% endraw %}

{% raw %}{% block nav_items %}{% endraw %}
{% for entity in entities -%}
<a href="{{entity.route}}" class="block px-4 py-2 hover:bg-gray-700">{{entity.display_name}}</a>
{% endfor -%}
{% raw %}{% endblock nav_items %}{% endraw %}

{% raw %}{% block content %}{% endraw %}
<div class="mb-4">
  <h1 class="text-2xl font-bold mb-6">Admin Dashboard</h1>
  
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    {% for entity in entities -%}
    <div class="bg-white rounded shadow p-6 hover:shadow-lg transition-shadow">
      <h2 class="text-xl font-semibold mb-2">{{entity.display_name}}</h2>
      <p class="text-gray-600 mb-4">Manage {{entity.display_name}} records</p>
      <a href="{{entity.route}}" 
         class="inline-block bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
        Manage {{entity.display_name}}
      </a>
    </div>
    {% endfor -%}
  </div>
</div>
{% raw %}{% endblock content %}{% endraw %}

