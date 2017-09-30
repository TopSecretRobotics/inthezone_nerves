<template lang="pug">
tr
  td <code> ({{ item.index }}) {{ item.value.direction }} {{ item.value.id }} {{ item.value.__typename }} {{ item.value.frame && item.value.frame.length }} {{ item.value.frame }}</code>
</template>

<script>
export default {
  name: 'SocketEventItem',
  props: ['item']
}
</script>
