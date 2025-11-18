<template>
  <div class="space-y-3">
    <OverviewCard
      v-for="card in cards"
      :key="card.id"
      :title="card.title"
      @click="$emit('navigate', card.section)"
    >
      <component :is="card.content" v-if="typeof card.content === 'object'" />
      <span v-else v-html="card.content"></span>
    </OverviewCard>
  </div>
</template>

<script setup>
import OverviewCard from '@/components/ui/OverviewCard.vue'

defineProps({
  cards: {
    type: Array,
    required: true
  }
})

defineEmits(['navigate'])
</script>
