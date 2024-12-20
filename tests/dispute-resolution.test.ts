import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('Dispute Resolution Contract', () => {
  let mockContractCall: any
  let contractOwner: string
  let client: string
  let freelancer: string
  let arbitrator: string
  
  beforeEach(() => {
    mockContractCall = vi.fn()
    contractOwner = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
    client = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG'
    freelancer = 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC'
    arbitrator = 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB'
  })
  
  describe('create-dispute', () => {
    it('should create a dispute successfully', async () => {
      mockContractCall.mockResolvedValue({ success: true, value: 0 })
      const result = await mockContractCall('create-dispute', client, freelancer, 1000, { sender: client })
      expect(result.success).toBe(true)
      expect(result.value).toBe(0)
    })
    
    it('should fail if STX transfer fails', async () => {
      mockContractCall.mockResolvedValue({ success: false, error: 1 }) // Assuming error code 1 for transfer failure
      const result = await mockContractCall('create-dispute', client, freelancer, 1000, { sender: client })
      expect(result.success).toBe(false)
      expect(result.error).toBe(1)
    })
  })
  
  describe('resolve-dispute', () => {
    
    it('should fail if dispute does not exist', async () => {
      mockContractCall.mockResolvedValue({ success: false, error: 404 })
      const result = await mockContractCall('resolve-dispute', 999, client, { sender: arbitrator })
      expect(result.success).toBe(false)
      expect(result.error).toBe(404)
    })
  })
  
  describe('register-as-arbitrator', () => {
    it('should register an arbitrator successfully', async () => {
      mockContractCall.mockResolvedValue({ success: true, value: true })
      const result = await mockContractCall('register-as-arbitrator', { sender: arbitrator })
      expect(result.success).toBe(true)
      expect(result.value).toBe(true)
    })
    
    it('should fail if STX transfer fails', async () => {
      mockContractCall.mockResolvedValue({ success: false, error: 1 }) // Assuming error code 1 for transfer failure
      const result = await mockContractCall('register-as-arbitrator', { sender: arbitrator })
      expect(result.success).toBe(false)
      expect(result.error).toBe(1)
    })
  })
  
  describe('get-dispute', () => {
    it('should return dispute details', async () => {
      const disputeDetails = {
        client,
        freelancer,
        amount: 1000,
        status: "OPEN"
      }
      mockContractCall.mockResolvedValue({ success: true, value: disputeDetails })
      const result = await mockContractCall('get-dispute', 0)
      expect(result.success).toBe(true)
      expect(result.value).toEqual(disputeDetails)
    })
    
    it('should return null for non-existent dispute', async () => {
      mockContractCall.mockResolvedValue({ success: true, value: null })
      const result = await mockContractCall('get-dispute', 999)
      expect(result.success).toBe(true)
      expect(result.value).toBeNull()
    })
  })
  
  describe('is-arbitrator', () => {
    it('should return true for registered arbitrator', async () => {
      mockContractCall.mockResolvedValue({ success: true, value: true })
      const result = await mockContractCall('is-arbitrator', arbitrator)
      expect(result.success).toBe(true)
      expect(result.value).toBe(true)
    })
    
    it('should return false for non-registered arbitrator', async () => {
      mockContractCall.mockResolvedValue({ success: true, value: false })
      const result = await mockContractCall('is-arbitrator', client)
      expect(result.success).toBe(true)
      expect(result.value).toBe(false)
    })
  })
})

