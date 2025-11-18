import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Button from './Button.vue'

describe('Button', () => {
  it('renders slot content', () => {
    const wrapper = mount(Button, {
      slots: {
        default: 'Click me'
      }
    })

    expect(wrapper.text()).toBe('Click me')
    expect(wrapper.find('button').exists()).toBe(true)
  })

  it('emits click event when clicked', async () => {
    const wrapper = mount(Button, {
      slots: {
        default: 'Click me'
      }
    })

    await wrapper.trigger('click')
    expect(wrapper.emitted()).toHaveProperty('click')
    expect(wrapper.emitted('click')).toHaveLength(1)
  })

  it('is disabled when disabled prop is true', () => {
    const wrapper = mount(Button, {
      props: {
        disabled: true
      },
      slots: {
        default: 'Disabled'
      }
    })

    expect(wrapper.element.disabled).toBe(true)
  })

  it('does not emit click when disabled', async () => {
    const wrapper = mount(Button, {
      props: {
        disabled: true
      },
      slots: {
        default: 'Disabled'
      }
    })

    await wrapper.trigger('click')
    expect(wrapper.emitted('click')).toBeFalsy()
  })

  it('accepts different variants', () => {
    const variants = ['primary', 'secondary', 'soft']

    variants.forEach(variant => {
      const wrapper = mount(Button, {
        props: { variant },
        slots: { default: 'Button' }
      })

      expect(wrapper.find('button').exists()).toBe(true)
      wrapper.unmount()
    })
  })

  it('accepts different sizes', () => {
    const sizes = ['xs', 'sm', 'md', 'lg', 'xl']

    sizes.forEach(size => {
      const wrapper = mount(Button, {
        props: { size },
        slots: { default: 'Button' }
      })

      expect(wrapper.find('button').exists()).toBe(true)
      wrapper.unmount()
    })
  })
})
