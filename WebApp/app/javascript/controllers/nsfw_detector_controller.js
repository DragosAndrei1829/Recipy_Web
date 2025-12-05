import { Controller } from "@hotwired/stimulus"

// NSFW.js Content Moderation Controller
// Automatically detects inappropriate images before upload
export default class extends Controller {
  static targets = ["input", "preview", "warning", "submitButton"]
  static values = {
    threshold: { type: Number, default: 0.7 },
    enabled: { type: Boolean, default: true }
  }

  model = null
  isLoading = false
  flaggedFiles = new Set()

  async connect() {
    if (!this.enabledValue) return
    
    // Lazy load NSFW.js model
    this.loadModel()
  }

  async loadModel() {
    if (this.model || this.isLoading) return
    
    this.isLoading = true
    
    try {
      // Dynamically import nsfwjs
      const nsfwjs = await import('https://cdn.jsdelivr.net/npm/nsfwjs@2.4.2/+esm')
      
      // Load the model (using the smaller MobileNetV2 model for faster loading)
      this.model = await nsfwjs.load('https://cdn.jsdelivr.net/npm/nsfwjs@2.4.2/model/', { size: 224 })
      console.log('NSFW detection model loaded')
    } catch (error) {
      console.warn('Failed to load NSFW model:', error)
      // Don't block uploads if model fails to load
    } finally {
      this.isLoading = false
    }
  }

  async checkFiles(event) {
    if (!this.enabledValue || !this.model) {
      // If model isn't loaded, allow upload but try to load for next time
      this.loadModel()
      return
    }

    const files = event.target.files
    if (!files || files.length === 0) return

    this.flaggedFiles.clear()
    this.hideWarning()

    // Check each file
    const checkPromises = Array.from(files).map((file, index) => 
      this.checkFile(file, index)
    )

    const results = await Promise.all(checkPromises)
    
    // If any files are flagged, show warning and prevent submission
    if (this.flaggedFiles.size > 0) {
      this.showWarning()
      this.disableSubmit()
      
      // Clear the input
      event.target.value = ''
      
      // Clear preview if exists
      if (this.hasPreviewTarget) {
        this.previewTarget.innerHTML = ''
      }
    } else {
      this.enableSubmit()
    }
  }

  async checkFile(file, index) {
    // Only check images
    if (!file.type.startsWith('image/')) return { safe: true }

    try {
      const img = await this.createImage(file)
      const predictions = await this.model.classify(img)
      
      // Check for NSFW content
      const nsfwCategories = ['Porn', 'Hentai', 'Sexy']
      const nsfw = predictions.find(p => 
        nsfwCategories.includes(p.className) && p.probability > this.thresholdValue
      )

      if (nsfw) {
        this.flaggedFiles.add(index)
        console.log(`Image ${index} flagged:`, nsfw.className, nsfw.probability)
        return { 
          safe: false, 
          reason: nsfw.className, 
          probability: nsfw.probability 
        }
      }

      return { safe: true }
    } catch (error) {
      console.warn('Error checking image:', error)
      // On error, allow the image (don't block legitimate uploads)
      return { safe: true }
    }
  }

  createImage(file) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = () => {
        URL.revokeObjectURL(img.src)
        resolve(img)
      }
      img.onerror = reject
      img.src = URL.createObjectURL(file)
    })
  }

  showWarning() {
    if (this.hasWarningTarget) {
      this.warningTarget.classList.remove('hidden')
    } else {
      // Create warning element if not exists
      const warning = document.createElement('div')
      warning.id = 'nsfw-warning'
      warning.className = 'mt-4 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl'
      warning.innerHTML = `
        <div class="flex items-start gap-3">
          <svg class="w-6 h-6 text-red-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
          </svg>
          <div>
            <h4 class="font-semibold text-red-800 dark:text-red-200">Conținut inadecvat detectat</h4>
            <p class="text-sm text-red-600 dark:text-red-300 mt-1">
              Una sau mai multe imagini par să conțină conținut inadecvat și nu pot fi încărcate. 
              Te rugăm să selectezi alte imagini.
            </p>
          </div>
        </div>
      `
      this.inputTarget.parentNode.appendChild(warning)
    }
  }

  hideWarning() {
    if (this.hasWarningTarget) {
      this.warningTarget.classList.add('hidden')
    } else {
      const warning = document.getElementById('nsfw-warning')
      if (warning) warning.remove()
    }
  }

  disableSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  enableSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    }
  }
}




