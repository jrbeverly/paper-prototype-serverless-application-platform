<template>
  <main>
    <h1>Items</h1>

    <ul v-if="items.length">
      <li v-for="item in items" :key="item.id">{{ item.name }}</li>
    </ul>
    <p v-else>No items yet.</p>

    <form @submit.prevent="addItem">
      <label>
        Name
        <input v-model="name" required />
      </label>
      <button type="submit" :disabled="submitting">Add</button>
    </form>

    <p v-if="error" role="alert">{{ error }}</p>
  </main>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const items = ref([])
const name = ref('')
const error = ref('')
const submitting = ref(false)

async function load() {
  error.value = ''
  const res = await fetch('/api/items')
  if (!res.ok) { error.value = `Failed to load items (${res.status})`; return }
  items.value = await res.json()
}

async function addItem() {
  submitting.value = true
  error.value = ''
  const res = await fetch('/api/items', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: name.value }),
  })
  submitting.value = false
  if (!res.ok) { error.value = `Failed to add item (${res.status})`; return }
  name.value = ''
  await load()
}

onMounted(load)
</script>
