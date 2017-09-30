<template lang="pug">
tr
  td <code> ({{ item.index }}) {{ item.value.__typename }}</code>
</template>

<script>
export default {
  name: 'ServerEventItem',
  props: ['item']
}
</script>
